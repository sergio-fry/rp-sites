require 'securerandom'

class Collection < S3Record
  def self.table_name; "collections"; end;
  ROOT_ID = "root"

  def add_site(site_id)
    self["sites"] ||= []
    self["sites"] << site_id
    self["sites"].uniq!
  end

  def sites
    Site.find_all(self["sites"] || [])
  end

  def self.root
    _root = find ROOT_ID rescue nil
    _root ||= begin
                collection = Collection.new
                collection.id = ROOT_ID
                collection.save

                collection
              end

    _root
  end
end
