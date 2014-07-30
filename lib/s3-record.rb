class S3Record
  attr_accessor :id

  class << self; attr_accessor :default_attributes end
  @default_attributes = {}

  def initialize(attributes={})
    @attributes = attributes
    self.id = SecureRandom.uuid
  end

  def attributes
    self.class.default_attributes.try(:merge, @attributes) || @attributes
  end

  def save
    connection.write([self.class.table_name, id].join("/"), to_json)
  end

  def update(attributes)
    @attributes = @attributes.merge(attributes)
    save
  end

  def delete
    connection.delete([self.class.table_name, id].join("/"))
  end

  def to_json
    { "id" => id,  "attributes" => @attributes }.to_json
  end

  def [](attr)
    attributes[attr.to_s]
  end

  def []=(attr, value)
    @attributes[attr.to_s] = value
  end

  def self.table_name; raise "Table name undefined"; end;

  def self.set_default_attributes(attributes)
    self.class_eval do
      @default_attributes = attributes.stringify_keys
    end
  end

  def self.connection=(connection)
    @@connection = connection
  end

  def self.connection
    @@connection.actors.first
  end

  def connection
    self.class.connection
  end

  def self.find(id)
    data = connection.read([table_name, id].join("/"))

    unless data.nil?
      attributes = JSON.parse(data)["attributes"]
      site = new attributes
      site.id = id

      site
    else
      raise "No #{self.to_s} record found ##{id}"
    end
  end

  def self.find_all(ids)
    ids.map { |id| [id, connection.future.read([table_name, id].join("/"))] }.map do |id, future|
      next if future.value.nil?

      attributes = JSON.parse(future.value)["attributes"]
      site = new attributes
      site.id = id

      site
    end.compact
  end
end
