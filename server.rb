require 'sinatra/base'
require "s3-storage"
require "site"


class Server < Sinatra::Base
  class StubStore
    def initialize
      @store = {}
    end

    def write(key, value)
      @store[key] = value
    end

    def read(key)
      @store[key]
    end

    def delete(key)
      @store.delete key
    end
  end

  def initialize(*args)
    #@connection = CelluloidS3::Storage.new
    @connection = StubStore.new

    Site.connection(@connection)

    super(*args)
  end

  get '/' do
    "Hello World!"
  end

  get "/sites/:id" do
    @site = Site.find params[:id]
    erb "sites/show".to_sym, :locals => { :site => @site }
  end

  post "/sites" do
    @site = Site.new :domain => params[:domain]
    @site.save

    @site.to_json
  end
end
