# Module that implements a method to get contacts for a user or group
module GoogleContactsApi
  module Contacts
    attr_accessor :batched_contacts, :batched_status_handlers

    # Google Contacts API limits it to 100.
    BATCH_SIZE = 100

    RETRY_BATCH_DELAY_AFTER_ERROR = 30

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

    # Compatibility method for older code before rename to get_contacts
    def contacts(params = {})
      get_contacts(params)
    end

    def contacts_updated_min(updated_min, params = {})
      params['updated-min'] = GoogleContactsApi::Api.format_time_for_xml(updated_min)
      get_contacts(params)
    end

    def query_contacts(query, params = {})
      params['q'] = query
      get_contacts(params)
    end

    def get_contact(id_url)
      GoogleContactsApi::Contact.find(id_url, @api)
    end

    def create_contact(attrs)
      GoogleContactsApi::Contact.create(attrs, @api)
    end

    # An etag of '*' will bypass the etag check and delete the contact no matter the etag
    def delete_contact(id_url, etag = '*')
      url =id_url.sub('http://', 'https://').sub(GoogleContactsApi::Api::BASE_URL, '')
      @api.delete(url,  {}, 'If-Match' => etag)
    end

    def batch_create_or_update(contact, &block)
      @batched_contacts ||= []
      @batched_status_handlers ||= []

      @batched_contacts << contact
      @batched_status_handlers << block

      send_batched_requests if @batched_contacts.size >= BATCH_SIZE
    end

    def send_batched_requests
      return unless @batched_contacts && @batched_contacts.size > 0
      statuses = send_batch_with_retries(@batched_contacts)

      statuses.each_with_index { |status, index|
        @batched_status_handlers[index].call(status)
      }
    ensure
      @batched_contacts = []
      @batched_status_handlers = []
    end

    def send_batch_with_retries(contacts, num_retries = 1)
      send_batch_create_or_update(contacts)
    rescue InternalServerError => e
      # Google Contacts API somtimes returns temporary errors that are worth giving another try to a bit later.
      raise e unless num_retries > 0
      sleep(RETRY_BATCH_DELAY_AFTER_ERROR)
      send_batch_with_retries(contacts, num_retries - 1)
    end

    def send_batch_create_or_update(contacts)
      xml = batch_xml(contacts)
      @last_batch_xml = xml
      response = @api.post('contacts/default/full/batch', xml, {'alt' => ''}, 'Content-Type' => 'application/atom+xml')
      raise_if_failed_response(response)
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

    # Helpful for logging/debugging in error conditions
    def last_batch_xml
      @last_batch_xml
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
        when 400...499; raise
        when 500...600; raise InternalServerError
      end
    end

    class InternalServerError < StandardError
    end
  end
end