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

    def etag
      self['gd$etag']
    end

    # Returns link entry for the photo
    def photo_link_entry
      self["link"].find { |l| l.rel == "http://schemas.google.com/contacts/2008/rel#photo" }
    end

    # Returns link for photo
    # (still need authentication to get the photo data, though)
    def photo_link
      _link = photo_link_entry
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
      # etag is always specified if actual photo is present
      _link = photo_link_entry
      return nil unless @api && _link['gd$etag']

      response = @api.oauth.get(_link.href)
      if GoogleContactsApi::Api.parse_response_code(response) == 200
        {
            etag: _link['gd$etag'].gsub('"',''),
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
      nested_field_name_only 'gd$name', 'gd$givenName'
    end
    def given_name_yomi
      nested_field_yomi_only 'gd$name', 'gd$givenName'
    end
    def family_name
      nested_field_name_only 'gd$name', 'gd$familyName'
    end
    def family_name_yomi
      nested_field_yomi_only 'gd$name', 'gd$familyName'
    end
    def full_name
      nested_t_field_or_nil 'gd$name', 'gd$fullName'
    end
    def additional_name
      nested_field_name_only 'gd$name', 'gd$additionalName'
    end
    def additional_name_yomi
      nested_field_yomi_only 'gd$name', 'gd$additionalName'
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
      format_entities('gd$organization').map do |org|
        if org[:org_name]
          org[:org_name_yomi] = org[:org_name]['yomi'] if org[:org_name]['yomi']
          org[:org_name] = name_only(org[:org_name])
        end
        org
      end
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

  private
    def nested_field_name_only(level1, level2)
      name_only(self[level1][level2]) if self[level1]
    end

    # Certain fields allow an optional Japanese yomigana subfield (making it
    # sometimes be a hash which can cause a bug if you're expecteding a string)
    # This normalizes the field to a string whether the yomi is present or not
    # This method also accounts for any other unexpected fields
    def name_only(name)
      return name if name.blank?
      return name if name.is_a?(String)
      name['$t']
    end

    def nested_field_yomi_only(level1, level2)
      self[level1][level2]['yomi'] if self[level1]
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
