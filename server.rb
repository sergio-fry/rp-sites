require 'sinatra/base'
require "s3-storage"
require 's3-record'
require "site"
require "site_worker"
require "collection"


class Server < Sinatra::Base
  set :show_exceptions, true

  def initialize(*args)
    @connection = CelluloidS3::Storage.supervise
    #@connection = CelluloidS3::StubStorage.supervise

    S3Record.connection = @connection

    super(*args)
  end

  def site_worker
    @site_worker_superviser ||= SiteWorker.supervise
    
    @site_worker_superviser.actors.first
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

    collection = Collection.root
    collection.add_site(site.id)
    collection.save

    site.to_json
  end

  delete "/sites/:id" do
    site = Site.find params[:id]
    site.delete

    "#{params[:id]} DELETED"
  end

  get "/admin" do
    protected!
    
    "Здравствуйте, админ!"
  end
end
