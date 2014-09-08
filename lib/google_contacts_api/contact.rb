module GoogleContactsApi
  # Represents a single contact.
  # Methods we could implement:
  # :categories, (:content again), :links, (:title again), :email
  # :extended_properties, :deleted, :im, :name,
  # :organizations, :phone_numbers, :structured_postal_addresses, :where
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
      spouse_rel = relations.find {|r| r.rel = 'spouse'}
      spouse_rel['$t'] if spouse_rel
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

    def prep_update(changes)
      @changes ||= {}
      @changes.merge!(changes)
    end

    def send_update(changes=nil)
      changes ||= @changes
      attrs = attrs_for_update(changes)
      attrs[:updated] = GoogleContactsApi::Api.format_time_for_xml(Time.now)
      attrs[:etag] = etag
      attrs[:id] = id

      xml = xml_for_update(attrs)
      url = id.sub('http://', 'https://').sub(GoogleContactsApi::Api::BASE_URL, '')
      response = @api.put(url, xml, {}, { 'If-Match' => etag })
      code = GoogleContactsApi::Api.parse_response_code(response)

      if code == 200
        reload_from_data(JSON.parse(response.body)['entry'][0])
      elsif code == 412
        # Contacts API gives HTTP 412 Precondition Failed if contact has been edited since you attempted the edit
        # See https://developers.google.com/google-apps/contacts/v3/
        raise 'HTTP 214: Contact Modified Since Load'
      else
        raise code
      end
    end

    def reload_from_data(parsed_data)
      keys.each { |k| delete(k) }
      deep_update(parsed_data)
    end

    def xml_for_update(attrs)
      @@edit_contact_template ||= File.new(File.dirname(__FILE__) + '/templates/contact.xml.erb').read
      ERB.new(@@edit_contact_template).result(OpenStruct.new(contact: attrs, action: :update).instance_eval { binding })
    end
    
  private
    def attrs_for_update(changes)
      fields = [:name_prefix, :given_name, :additional_name, :family_name, :name_suffix, :content,
                :emails, :phone_numbers, :addresses, :organizations, :websites]
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
      formatted = {}

      formatted[:primary] = unformatted['primary'] ? unformatted['primary'] == 'true' : false
      unformatted.delete 'primary'

      if unformatted['rel']
        formatted[:rel] = unformatted['rel'].gsub('http://schemas.google.com/g/2005#', '')
        unformatted.delete 'rel'
      elsif default_rel
        formatted[:rel] = default_rel
      end

      if text_key
        formatted[text_key] = unformatted['$t']
        unformatted.delete '$t'
      end

      unformatted.each do |key, value|
        formatted[key.sub('gd$', '').underscore.to_sym] = value['$t'] ? value['$t'] : value
      end

      formatted
    end

    def format_address(unformatted)
      return format_entity(unformatted, 'work')
    end

    def format_phone_number(unformatted)
      format_entity unformatted, nil, :number
    end
  end
end