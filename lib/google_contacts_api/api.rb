require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'ostruct'

module GoogleContactsApi
  class ApiError < StandardError; end
  class UnauthorizedError < ApiError; end
  
  class Api
    # keep separate in case of new auth method
    BASE_URL = "https://www.google.com/m8/feeds/"

    attr_reader :oauth
    def initialize(oauth)
      # TODO: Later, accept ClientLogin
      @oauth = oauth
    end

    # Get request to specified link, with query params
    def get(link, params = {}, headers = {})
      request(:get, link, params, '', headers)
    end

    # Post request to specified link, with query params
    # Not tested with oauth gem, only oauth2
    def post(link, body = '', params = {}, headers = {})
      request(:post, link, params, body, headers)
    end

    # Not tested with oauth gem, only oauth2
    def put(link, body = '', params = {}, headers = {})
      request(:put, link, params, body, headers)
    end

    # For get, post, put, delete, always use JSON, it's simpler
    # and lets us use Hashie::Mash. Note that in the JSON conversion from XML,
    # ":" is replaced with $, element content is keyed with $t
    # Raise UnauthorizedError if not authorized.
    def request(http_method, link, params, body = '', headers = {})
      begin
        merged_params = params_with_defaults(params)
        path = "#{BASE_URL}#{link}?#{merged_params.to_query}"
        opts = {}
        opts[:body] = body if body != '' && !body.nil?
        opts[:headers] = headers if headers != {} && !headers.nil?

        result = @oauth.request(http_method, path, opts)
      rescue => e
        # TODO: OAuth 2.0 will raise a real error
        raise UnauthorizedError if defined?(e.response) && self.class.parse_response_code(e.response) == 401
        raise e
      end

      # OAuth 1.0 uses Net::HTTP internally
      raise UnauthorizedError if result.is_a?(Net::HTTPUnauthorized)
      result
    end

    # Delete request to specified link, with query params
    # Not tried yet
    def delete(link, params = {}, headers = {})
      request(:delete, link, params, '', headers)
    end
    
    # Parse the response code
    # Needed because of difference between oauth and oauth2 gems
    def self.parse_response_code(response)
      return nil if response.nil?
      (defined?(response.code) ? response.code : response.status).to_i
    end

    def self.format_time_for_xml(time)
      time.utc.strftime '%Y-%m-%dT%H:%M:%S.%3NZ'
    end

    private

    def params_with_defaults(params)
      p = params || {}
      p['alt'] = 'json' unless p['alt']
      p['v'] = '3' unless p['v']
      p
    end
  end
end