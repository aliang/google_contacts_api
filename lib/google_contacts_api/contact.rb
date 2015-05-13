module GoogleContactsApi
  # Represents a single contact.
  class Contact < GoogleContactsApi::Result
    # Returns the array of links, as link is an array for Hashie.
    def links
      self["link"].map { |l| l.href }
    end

    # Returns link to get this contact
    def self_link
      _link = self["link"].find { |l| l.rel == "self" }
      _link ? _link.href : nil
    end

    # Returns alternative, possibly off-Google home page link
    def alternate_link
      _link = self["link"].find { |l| l.rel == "alternate" }
      _link ? _link.href : nil
    end

    # Returns link for photo
    # (still need authentication to get the photo data, though)
    def photo_link
      _link = self["link"].find { |l| l.rel == "http://schemas.google.com/contacts/2008/rel#photo" }
      _link ? _link.href : nil
    end

    # Returns binary data for the photo. You can probably
    # use it in a data-uri. This is in PNG format.
    def photo
      return nil unless @api && photo_link
      response = @api.oauth.get(photo_link)

      case GoogleContactsApi::Api.parse_response_code(response)
        # maybe return a placeholder instead of nil
        when 400; return nil
        when 401; return nil
        when 403; return nil
        when 404; return nil
        when 400...500; return nil
        when 500...600; return nil
        else; return response.body
      end
    end

    # Returns link to add/replace the photo
    def edit_photo_link
      _link = self["link"].find { |l| l.rel == "http://schemas.google.com/contacts/2008/rel#edit_photo" }
      _link ? _link.href : nil
    end

    # Returns link to edit the contact
    def edit_link
      _link = self["link"].find { |l| l.rel == "edit" }
      _link ? _link.href : nil
    end

    # Returns all phone numbers for the contact
    def phone_numbers
      self["gd$phoneNumber"] ? self["gd$phoneNumber"].map { |e| e['$t'] } : []
    end

    # Returns all email addresses for the contact
    def emails
      self["gd$email"] ? self["gd$email"].map { |e| e.address } : []
    end

    # Returns primary email for the contact
    def primary_email
      if self["gd$email"]
        _email = self["gd$email"].find { |e| e.primary == "true" }
        _email ? _email.address : nil
      else
        nil # no emails at all
      end
    end

    # Returns all instant messaging addresses for the contact.
    # Doesn't yet distinguish protocols
    def ims
      self["gd$im"] ? self["gd$im"].map { |i| i.address } : []
    end

    def photo_with_metadata
      photo_link_entry = self['link'].find { |l| l.rel == 'http://schemas.google.com/contacts/2008/rel#photo' }
      return nil unless @api && photo_link_entry['gd$etag'] # etag is always specified if actual photo is present

      response = @api.oauth.get(photo_link)
      if GoogleContactsApi::Api.parse_response_code(response) == 200
        {
            etag: photo_link_entry['gd$etag'].gsub('"',''),
            content_type: response.headers['content-type'],
            data: response.body
        }
      end
    rescue => e
      if defined?(e.response)
        case GoogleContactsApi::Api.parse_response_code(e.response)
          # maybe return a placeholder instead of nil
          when 400; return nil
          when 401; return nil
          when 403; return nil
          when 404; return nil
          when 400...500; return nil
          when 500...600; return nil
        end
      end
      raise e
    end

    # Convenience method to return a nested $t field.
    # If the field doesn't exist, return nil
    def nested_t_field_or_nil(level1, level2)
      if self[level1]
        self[level1][level2] ? self[level1][level2]['$t']: nil
      end
    end

    def given_name
      nested_t_field_or_nil 'gd$name', 'gd$givenName'
    end
    def family_name
      nested_t_field_or_nil 'gd$name', 'gd$familyName'
    end
    def full_name
      nested_t_field_or_nil 'gd$name', 'gd$fullName'
    end
    def additional_name
      nested_t_field_or_nil 'gd$name', 'gd$additionalName'
    end
    def name_prefix
      nested_t_field_or_nil 'gd$name', 'gd$namePrefix'
    end
    def name_suffix
      nested_t_field_or_nil 'gd$name', 'gd$nameSuffix'
    end
    def birthday
      if self['gContact$birthday']
        day, month, year = self['gContact$birthday']['when'].split('-').reverse
        { year: year == '' ? nil : year.to_i, month: month.to_i, day: day.to_i }
      end
    end

    def relations
      self['gContact$relation'] ? self['gContact$relation'] : []
    end

    # Returns the spouse of the contact. (Assumes there's only one.)
    def spouse
      spouse_rel = relations.find {|r| r[:rel] == 'spouse'}
      spouse_rel['$t'] if spouse_rel
    end

    def group_membership_info
      if self['gContact$groupMembershipInfo']
        self['gContact$groupMembershipInfo'].map(&method(:format_group_membership))
      else
        []
      end
    end
    def format_group_membership(membership)
      { deleted: membership['deleted'] == 'true', href: membership['href'] }
    end
    def group_memberships
      group_membership_info.select { |info| !info[:deleted] }.map { |info| info[:href] }
    end
    def deleted_group_memberships
      group_membership_info.select { |info| info[:deleted] }.map { |info| info[:href] }
    end
    def prep_add_to_group(group)
      prep_changes(group_memberships: (group_memberships + prepped_changes[:group_memberships].to_a + [group.id]).uniq,
                   deleted_group_memberships: deleted_group_memberships.reject { |deleted| deleted == group.id  })
    end

    # Return an Array of Hashes representing addresses with formatted metadata.
    def addresses
      format_entities('gd$structuredPostalAddress', :format_address)
    end

    def organizations
      format_entities('gd$organization')
    end
    def websites
      format_entities('gContact$website')
    end

    # Return an Array of Hashes representing phone numbers with formatted metadata.
    def phone_numbers_full
      format_entities('gd$phoneNumber', :format_phone_number)
    end

    # Return an Array of Hashes representing emails with formatted metadata.
    def emails_full
      format_entities('gd$email')
    end

    def etag
      self['gd$etag']
    end

    def formatted_attrs
      attrs_for_update({})
    end

    def attrs_with_changes
      attrs_for_update(prepped_changes)
    end

    def prep_changes(changes)
      @changes ||= {}
      @changes.merge!(changes)
    end

    def prepped_changes
      @changes ||= {}
    end

    def create_or_update(changes=nil)
      if id
        send_update(changes)
      else
        send_create(changes)
      end
    end

    def self.find(id_url, api)
      url = id_url.sub('http://', 'https://').sub(GoogleContactsApi::Api::BASE_URL, '').sub('/base/', '/full/')
      contact_from_response(api.get(url), api)
    end

    def self.create(attrs, api)
      contact_from_response(call_api_create(attrs, api), api)
    end

    def batch_create_or_update_xml(batch_id)
      id ? batch_update_xml(batch_id) : batch_create_xml(batch_id)
    end

    def batch_update_xml(batch_id)
      attrs = full_attrs_for_update
      return unless attrs
      attrs[:batch_id] = batch_id
      attrs[:batch_operation] = 'update'
      xml_for_update(attrs)
    end

    def batch_create_xml(batch_id)
      return if prepped_changes == {}
      attrs = attrs_for_update(prepped_changes)
      attrs[:batch_id] = batch_id
      attrs[:batch_operation] = 'insert'
      Contact.xml_for_create(attrs)
    end

    def full_attrs_for_update(changes = nil)
      changes ||= @changes
      return unless changes
      attrs = attrs_for_update(changes)
      attrs[:updated] = GoogleContactsApi::Api.format_time_for_xml(Time.now)
      attrs[:etag] = etag
      attrs[:id] = id
      attrs
    end

    def send_update(changes = nil)
      attrs = full_attrs_for_update(changes)
      return unless attrs

      xml = xml_for_update(attrs)
      # Needs to be sent to ../full/.. not /base/ to support group membership info
      url = id.sub('http://', 'https://').sub('/base/', '/full/').sub(GoogleContactsApi::Api::BASE_URL, '')

      response = @api.put(url, xml, {}, 'If-Match' => etag, 'Content-Type' => 'application/atom+xml')
      reload_from_data(Contact.parse_response(response))
    end

    def send_create(changes=nil)
      changes ||= @changes
      return unless changes
      reload_from_data(Contact.parse_response(Contact.call_api_create(attrs_for_update(changes), @api)))
    end

    def self.encode(value, xml_format)
      value.to_s.gsub("\v", "\n").encode(xml: xml_format)
    end

    def self.evaluate_template(template, contact, action)
      encode = lambda { |value, xml_format| Contact.encode(value, xml_format) }
      ERB.new(template).result(binding)
    end

    def self.xml_for_create(attrs)
      @@new_contact_template ||= File.new(File.dirname(__FILE__) + '/templates/contact.xml.erb').read
      Contact.evaluate_template(@@new_contact_template, attrs, :create)
    end

    def xml_for_update(attrs)
      @@edit_contact_template ||= File.new(File.dirname(__FILE__) + '/templates/contact.xml.erb').read
      Contact.evaluate_template(@@edit_contact_template, attrs, :update)
    end

    def self.call_api_create(attrs, api)
      api.post('contacts/default/full', xml_for_create(attrs), {}, 'Content-Type' => 'application/atom+xml')
    end

    def self.contact_from_response(response, api)
      self.new(parse_response(response), nil, api)
    end

    def self.parse_response(response)
      raise_if_failed_response(response)
      entry = Hashie::Mash.new(JSON.parse(response.body)).entry
      entry.is_a?(Array) ? entry[0] : entry
    end

    def self.raise_if_failed_response(response)
      # TODO: Define some fancy exceptions
      case GoogleContactsApi::Api.parse_response_code(response)
        when 401; raise
        when 403; raise
        when 404; raise

        # Contacts API gives HTTP 412 Precondition Failed if contact has been edited since you attempted the edit
        # See https://developers.google.com/google-apps/contacts/v3/
        when 412; raise 'HTTP 412: Contact Modified Since Load'

        when 400...500; raise
        when 500...600; raise
      end
    end

    # Helper functions below, but not private for sake of easier testing

    def reload_from_data(parsed_data)
      keys.each { |k| delete(k) }
      deep_update(parsed_data)
    end

    def attrs_for_update(changes)
      fields = [:name_prefix, :given_name, :additional_name, :family_name, :name_suffix, :content,
                :emails, :phone_numbers, :addresses, :organizations, :websites, :group_memberships, :deleted_group_memberships]
      Hash[fields.map { |f| [ f, changes.has_key?(f) ? changes[f] : value_for_field(f) ] } ]
    end

    def value_for_field(field)
      method_exceptions = {
          phone_numbers: :phone_numbers_full,
          emails: :emails_full
      }
      method = method_exceptions.has_key?(field) ? method_exceptions[field] : field
      send(method)
    end

    def format_entities(key, format_method=:format_entity)
      self[key] ? self[key].map(&method(format_method)) : []
    end

    def format_entity(unformatted, default_rel=nil, text_key=nil)
      attrs = Hash[unformatted.map { |key, value|
        case key
        when 'primary'
          [:primary, value == true || value == 'true']
        when 'rel'
          [:rel, value.gsub('http://schemas.google.com/g/2005#', '')]
        when '$t'
          [text_key || key.underscore.to_sym, value]
        else
          [key.sub('gd$', '').underscore.to_sym, value['$t'] ? value['$t'] : value]
        end
      }]
      attrs[:rel] ||= default_rel
      attrs[:primary] = false if attrs[:primary].nil?
      attrs
    end

    def format_address(unformatted)
      address = format_entity(unformatted, 'work')
      address[:street] ||= nil
      address[:city] ||= nil
      address[:region] ||= nil
      address[:postcode] ||= nil
      address[:country] = format_country(unformatted['gd$country'])
      address.delete :formatted_address
      address
    end

    def format_country(country)
      return nil unless country
      country['$t'].nil? || country['$t'] == '' ? country['code'] : country['$t']
    end

    def format_phone_number(unformatted)
      format_entity unformatted, nil, :number
    end
  end
end
