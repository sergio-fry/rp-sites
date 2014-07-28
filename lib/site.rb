require 'securerandom'

class Site < S3Record
  def self.table_name; "sites"; end;
end
