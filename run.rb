require "bundler"
require "./s3-storage"

store = CelluloidS3::Storage.new

store.write(1, { :name => "Sergei Udalov", :city => "Electrougli" }.to_json)
store.write(2, { :name => "Igor Udalov", :city => "Pushkino" }.to_json)
puts store.read(1)
store.write(2, { :name => "Sergei Udalov", :city => "Electrougli" }.to_json)
puts store.read(1)

sleep
