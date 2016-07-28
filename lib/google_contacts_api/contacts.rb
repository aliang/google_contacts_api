# Module that implements a method to get contacts for a user or group
module GoogleContactsApi
  module Contacts
    # Retrieve the contacts for this user or group
    def get_contacts(params = {})
      # TODO: Should return empty ContactSet (haven't implemented one yet)
      return [] unless @api
      params = params.with_indifferent_access

      # compose params into a string
      # See http://code.google.com/apis/contacts/docs/3.0/reference.html#Parameters
      # alt, q, max-results, start-index, updated-min,
      # orderby, showdeleted, requirealldeleted, sortorder, group
      params["max-results"] = 100000 unless params.key?("max-results")
      url = "contacts/default/full"
      response = @api.get(url, params)

      handle_error(response)
      GoogleContactsApi::ContactSet.new(response.body, @api)
    end

    # Retrieve a single contact for this user or group
    def get_contact(params = {})
      return nil unless @api
      params = params.with_indifferent_access
      url = "contacts/default/full/#{params[:contact_id]}"

      response = @api.get(url, params)
      handle_error(response)

      entry_body = JSON.parse(response.body)['entry']
      GoogleContactsApi::Contact.new(entry_body, nil, api = @api)
    end

    def handle_error(response)
      # TODO: Define some fancy exceptions
      case GoogleContactsApi::Api.parse_response_code(response)
      when 401; raise
      when 403; raise
      when 404; raise
      when 400...500; raise
      when 500...600; raise
      end
    end
  end
end
