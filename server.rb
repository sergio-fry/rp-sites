require 'sinatra/base'
require "s3-storage"
require "site"
require "collection"


class Server < Sinatra::Base
  def initialize(*args)
    #@connection = CelluloidS3::Storage.new
    @connection = CelluloidS3::StubStorage.new

    S3Record.connection(@connection)

    super(*args)
  end

  get '/' do
    collection = Collection.root
    erb "collections/show".to_sym, :locals => { :collection => collection }
  end

  get "/sites/:id" do
    site = Site.find params[:id]
    erb "sites/show".to_sym, :locals => { :site => site }
  end

  post "/sites" do
    site = Site.new :domain => params[:domain]
    site.save

    collection = Collection.root
    collection.add_site(site.id)
    collection.save

    site.to_json
  end
end
