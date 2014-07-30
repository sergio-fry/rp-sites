require 'sinatra/base'
require 'active_support'
require 'active_support/core_ext'
require 's3-storage'
require 's3-record'
require 'domain'
require 'site'
require 'site_worker'
require 'collection'

require 'rufus-scheduler'


class Server < Sinatra::Base
  set :show_exceptions, true
  set :static, true
  set :method_override, true

  def initialize(*args)
    if ENV["STUB_STORAGE"]
      @connection = CelluloidS3::StubStorage.supervise
    else
      @connection = CelluloidS3::Storage.supervise
    end

    S3Record.connection = @connection

    schedule_tasks

    super(*args)
  end

  helpers do
    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == [ENV["BASIC_AUTH_NAME"] || 'admin', ENV["BASIC_AUTH_PASSOWRD"] || 'password']
    end

    LETTERS = (("а".."я").to_a + [" "] * 10).freeze

    def lorem_ipsum(length=140)
      text = ""


      length.times do 
        text << LETTERS[rand(LETTERS.size)]
      end

      text
    end
  end

  get '/' do
    collection = Collection.root
    erb "collections/show".to_sym, :locals => { :collection => collection }, :layout => :layout
  end

  get "/sites/:id" do
    site = Site.find params[:id]
    erb "sites/show".to_sym, :locals => { :site => site }, :layout => :layout
  end

  post "/sites" do
    protected!

    site = Site.new :domain => params[:domain]
    site.save

    site_worker.async.fetch_title(site.id)
    site_worker.async.fetch_alexa_rank(site.id)
    site_worker.async.fetch_cy(site.id)

    collection = Collection.root
    collection.add_site(site.id)
    collection.save

    site.to_json
  end

  get "/sites/:id/edit" do
    protected!

    site = Site.find params[:id]
    erb "sites/edit".to_sym, :locals => { :site => site }, :layout => :layout
  end

  delete "/sites/:id" do
    protected!

    site = Site.find params[:id]
    site.delete

    "#{params[:id]} DELETED"
  end

  put "/sites/:id" do
    protected!

    site = Site.find params[:id]
    site.update(params[:site])

    site.to_json
  end

  get "/admin" do
    protected!
    
    "Здравствуйте, админ!"
  end

  get "/admin/run_tasks" do
    protected!

    collection = Collection.root
    collection.sites.each do |site|
      site_worker.async.fetch_title(site.id)
      site_worker.async.fetch_alexa_rank(site.id)
      site_worker.async.fetch_cy(site.id)
    end

    "Started! #{Time.now}"
  end

  private

  def schedule_tasks
    @scheduler = Rufus::Scheduler.new

    @scheduler.every '10m' do
      puts 'Checking ranks'
      collection = Collection.root

      collection.sites.each do |site|
        site_worker.async.fetch_alexa_rank(site.id)
        site_worker.async.fetch_cy(site.id)
      end
    end

    @scheduler.every '10m' do
      puts 'Checking sites titles'
      collection = Collection.root

      collection.sites.each do |site|
        site_worker.async.fetch_title(site.id)
      end
    end
  end

  def site_worker
    @site_worker_superviser ||= SiteWorker.supervise
    
    @site_worker_superviser.actors.first
  end
end
