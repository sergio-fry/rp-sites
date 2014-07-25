require 'sinatra/base'
require "./s3-storage"


class Server < Sinatra::Base
  def initialize(*args)
    @s3 = CelluloidS3::Storage.new
    super(*args)
  end

  get '/' do
    "Hello World!"
  end

  get '/aws' do
    @s3.read params[:key]
  end

  post '/aws' do
    @s3.write params[:key], params[:value]
  end
end
