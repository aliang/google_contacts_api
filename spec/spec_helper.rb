$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'json'
require 'hashie'
require 'net/http'
require 'google_contacts_api'
require 'active_support/core_ext/hash/conversions'
require 'webmock/rspec'
require 'rspec/matchers'
require 'equivalent-xml'

puts "Testing version #{GoogleContactsApi::VERSION}"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
end

def load_file(filename)
  f = File.open(File.join(File.dirname(__FILE__), filename))
  json = f.read
  f.close
  json
end

def read_spec_file(file)
  File.new(File.dirname(__FILE__) + '/' + file).read
end

def contact_set_json
  load_file("contact_set.json")
end

def group_set_json
  load_file("group_set.json")
end

def empty_contact_set_json
  load_file("empty_contact_set.json")
end

def contact_json_hash
  Hashie::Mash.new(JSON.parse(contact_set_json)).feed.entry.first
end

def contact_no_emails_json_hash
  Hashie::Mash.new(JSON.parse(contact_set_json)).feed.entry[1]
end

def contact_no_primary_email_json_hash
  Hashie::Mash.new(JSON.parse(contact_set_json)).feed.entry[2]
end

def group_json_hash
  Hashie::Mash.new(JSON.parse(group_set_json)).feed.entry.first
end