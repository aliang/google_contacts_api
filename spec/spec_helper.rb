$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'json'
require 'hashie'
require 'net/http'
require 'google_contacts_api'
require 'ostruct'
require 'rspec/matchers' # needed for equivalent-xml custom matcher `be_equivalent_to`
require 'equivalent-xml'
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f }

puts "Testing version #{GoogleContactsApi::Version::STRING}"

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
end

