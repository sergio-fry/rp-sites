require 'securerandom'

class Site
  TABLE = "sites"

  attr_accessor :id

  def initialize(attributes)
    @attributes = attributes
    self.id = SecureRandom.uuid
  end

  def save
    @@connection.write([TABLE, id].join("/"), to_json)
  end

  def to_json
    { "id" => id,  "attributes" => @attributes }.to_json
  end

  def [](attr)
    @attributes[attr]
  end

  def self.connection(connection)
    @@connection = connection
  end

  def self.find(id)
    data = @@connection.read([TABLE, id].join("/"))

    unless data.nil?
      attributes = JSON.parse(data)["attributes"]
      site = new attributes
      site.id = id

      site
    else
      raise "No site found"
    end
  end
end
