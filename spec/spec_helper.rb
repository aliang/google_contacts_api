$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'json'
require 'hashie'
require 'google_contacts_api'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.mock_framework = :rspec
end

def contact_set_json
  f = File.open("#{File.dirname(__FILE__)}/contact_set.json")
  json = f.read
  f.close
  json
end

def group_set_json
  f = File.open("#{File.dirname(__FILE__)}/group_set.json")
  json = f.read
  f.close
  json
end

def contact_json_hash
  Hashie::Mash.new(JSON.parse(contact_set_json)).feed.entry.first
end

def group_json_hash
  Hashie::Mash.new(JSON.parse(group_set_json)).feed.entry.first
end