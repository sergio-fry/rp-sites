require 'securerandom'
require 's3-record'

class Site < S3Record
  def self.table_name; "sites"; end;
end
