require "celluloid"
require "celluloid/io"
require "json"
require 'aws-sdk'
require 'open-uri'

module CelluloidS3
  class Aws
    include Celluloid
    include Celluloid::IO

    def initialize
      puts "init aws"
      @s3 = AWS::S3.new({
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
      })

      @bucket = @s3.buckets[ENV["AWS_BUCKET"]]
      @bucket.acl = :public_read
    end

    def write(key, value)
      @bucket.objects.create(key.to_s, value, :acl => :public_read)
    end

    def read(key)
      open("http://s3-eu-west-1.amazonaws.com/#{ENV['AWS_BUCKET']}/#{key}").read rescue nil
    end

    def delete(key)
      @bucket.objects.delete(key.to_s)
    end
  end

  class Storage
    include Celluloid
    include Celluloid::IO

    class Cache
      include Celluloid

      MAX_CACHE_SIZE = 10

      def initialize
        @data = {}
      end

      def read(key)
        @data[key]
      end

      def has_key?(key)
        @data.keys.include?(key)
      end

      def fetch(key)
        unless has_key? key
          write key, yield
        end

        read key
      end

      def write(key, value)
        cleanup if size_out_of_limit?

        @data[key] = value
      end

      def delete(key)
        @data.delete key
      end

      def cleanup
        @data = {}
      end

      private

      def size_out_of_limit?
        @data.size >= MAX_CACHE_SIZE
      end
    end

    def initialize
      @cache = Cache.new
      init_aws
    end

    def write(key, value)
      @cache.write(key, value)

      # потому что AWS блокирует выполнение
      Thread.new do
        aws.write(key, value)
      end
    end

    def read(key)
      @cache.fetch(key) do
        aws.read(key)
      end
    end

    def delete(key)
      @cache.delete key
      aws.delete(key)
    end

    private

    def aws
      @aws ||= Aws.new
    end

    def init_aws
      aws
    end
  end

  class StubStorage
    include Celluloid
    include Celluloid::IO

    def write(key, value)
      path = File.join("/tmp/stub-store", key)

      `mkdir -p #{File.dirname(path)}` rescue nil

      File.open( path, "wb") do |f|
        f.write(value)
      end
    end

    def read(key)
      File.read( File.join("/tmp/stub-store", key)) rescue nil
    end

    def delete(key)
      File.delete( File.join("/tmp/stub-store", key))
    end
  end
end

