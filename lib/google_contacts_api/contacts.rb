module GoogleContactsApi
  module Contacts
    # Retrieve the contacts for this user or group
    def contacts(params = {})
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

    def contacts_updated_min(updated_min)
      contacts('updated-min' => GoogleContactsApi::Api.format_time_for_xml(updated_min))
    end

    def query_contacts(query)
      contacts(q: query)
    end

    def get_contact(id_url)
      GoogleContactsApi::Contact.find(id_url, @api)
    end

    def create_contact(attrs)
      GoogleContactsApi::Contact.create(attrs, @api)
    end

    def batch_create_or_update(contacts)
      xml = batch_xml(contacts)
      response = @api.post('contacts/default/full/batch', xml, {'alt' => ''}, 'Content-Type' => 'application/atom+xml')

      parsed = GoogleContactsApi::XMLUtil.parse_as_if_alt_json(response.body)

      response_map = {}
      entries = parsed['feed']['entry']
      entries.each do |entry|
        batch_id = entry['batch$id']['$t'].to_i
        status = { code: entry['batch$status']['code'].to_i, reason: entry['batch$status']['reason']  }

        response_map[batch_id] = status

        if [200, 201].include?(status[:code])
          contacts[batch_id].reload_from_data(entry)
        end
      end

      responses = []
      for index in 0 .. contacts.size-1
        responses << response_map[index]
      end
      responses
    end

    def batch_xml(contacts)
      xml = <<-EOS
      <feed xmlns='http://www.w3.org/2005/Atom'
          xmlns:gContact='http://schemas.google.com/contact/2008'
          xmlns:gd='http://schemas.google.com/g/2005'
          xmlns:batch='http://schemas.google.com/gdata/batch'>
      EOS

      contacts.each_with_index do |contact, index|
        contact_xml = contact.batch_create_or_update_xml(index)
        xml += contact_xml if contact_xml
      end

      xml + '</feed>'
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
  end
end