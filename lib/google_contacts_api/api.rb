require 'active_support/core_ext'

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
    # For get, post, put, delete, always use JSON, it's simpler
    # and lets us use Hashie::Mash. Note that in the JSON conversion from XML,
    # ":" is replaced with $, element content is keyed with $t
    # Raise UnauthorizedError if not authorized.
    def get(link, params = {}, headers = {})
      params["alt"] = "json"
      result = @oauth.get("#{BASE_URL}#{link}?#{params.to_query}", headers)
      # For the full HTML we're matching against, see the spec
      # TODO: This could be pretty fragile.
      raise UnauthorizedError if result.is_a?(Net::HTTPUnauthorized)
      # raise UnauthorizedError if result.include?("Token invalid - Invalid AuthSub token.") && result.include?("Error 401")
      result
    end

    # Post request to specified link, with query params
    # Not tried yet, might be issues with params
    def post(link, params = {}, headers = {})
      raise NotImplementedError
      params["alt"] = "json"
      @oauth.post("#{BASE_URL}#{link}?#{params.to_query}", headers)
    end

    # Put request to specified link, with query params
    # Not tried yet
    def put(link, params = {}, headers = {})
      raise NotImplementedError
      params["alt"] = "json"
      @oauth.put("#{BASE_URL}#{link}?#{params.to_query}", headers)
    end

    # Delete request to specified link, with query params
    # Not tried yet
    def delete(link, params = {}, headers = {})
      raise NotImplementedError
      params["alt"] = "json"
      @oauth.delete("#{BASE_URL}#{link}?#{params.to_query}", headers)
    end
  end
end