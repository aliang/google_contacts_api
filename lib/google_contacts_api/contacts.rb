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

      raise_if_failed_response(response)
      GoogleContactsApi::ContactSet.new(response.body, @api)
    end

    def raise_if_failed_response(response)
      # TODO: Define some fancy exceptions
      case GoogleContactsApi::Api.parse_response_code(response)
        when 401; raise
        when 403; raise
        when 404; raise
        when 400...500; raise
        when 500...600; raise
      end
    end

    def create_contact(attrs)
      response = @api.post('default/full', xml_for_create_contact(attrs))
      raise_if_failed_response(response)

      body = response.body
      contact_set = GoogleContactsApi::ContactSet.new(body, @api)
      contact_set.first
    end

    def xml_for_create_contact(attrs)
      @@contact_xml_template ||= File.new(File.dirname(__FILE__) + '/templates/create_contact.erb').read
      ERB.new(@@contact_xml_template).result(OpenStruct.new(:contact => attrs).instance_eval { binding })
    end
  end
end