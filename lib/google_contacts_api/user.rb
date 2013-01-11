module GoogleContactsApi
  class User
    include GoogleContactsApi::Contacts
    
    attr_reader :api
    def initialize(oauth)
      @api = GoogleContactsApi::Api.new(oauth)
    end

    # Retrieve the groups for this user
    # TODO: Handle 403, 404, 401
    def groups(params = {})
      params = params.with_indifferent_access
      # compose params into a string
      # See http://code.google.com/apis/contacts/docs/3.0/reference.html#Parameters
      # alt, q, max-results, start-index, updated-min,
      # orderby, showdeleted, requirealldeleted, sortorder
      params["max-results"] = 100000 unless params.key?("max-results")

      # Set the version, for some reason the header is not effective on its own?
      params["v"] = 2

      url = "groups/default/full"
      # TODO: So weird thing, version 3 doesn't return system groups
      # When it does, uncomment this line and use it to request instead
      # response = @api.get(url, params)
      response = @api.get(url, params)

      case GoogleContactsApi::Api.parse_response_code(response)
      when 401; raise
      when 403; raise
      when 404; raise
      when 400...500; raise
      when 500...600; raise
      end
      GoogleContactsApi::GroupSet.new(response.body, @api)
    end
  end
end