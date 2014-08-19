module GoogleContactsApi
  class Contact < GoogleContactsApi::Result
    # :categories, (:content again), :links, (:title again), :email
    # :extended_properties, :deleted, :im, :name,
    # :organizations, :phone_numbers, :structured_postal_addresses, :where
    
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

    def relations
      self['gContact$relation'] ? self['gContact$relation'] : []
    end
    def spouse
      spouse_rel = relations.find {|r| r.rel = 'spouse'}
      spouse_rel['$t'] if spouse_rel
    end

    def addresses
      self['gd$structuredPostalAddress'] ? self['gd$structuredPostalAddress'].map(&method(:format_address)) : []
    end
    def phone_numbers_full
      self["gd$phoneNumber"] ? self["gd$phoneNumber"].map(&method(:format_phone_number)) : []
    end
    def emails_full
      self["gd$email"] ? self["gd$email"].map(&method(:format_email)) : []
    end

  private
    def format_address(unformatted)
      formatted = {}
      formatted[:rel] = unformatted['rel'] ? unformatted['rel'].gsub('http://schemas.google.com/g/2005#', '') : 'work'
      unformatted.delete 'rel'
      unformatted.each do |key, value|
        formatted[key.sub('gd$', '').underscore.to_sym] = value['$t']
      end
      formatted
    end

    def format_email_or_phone(unformatted)
      formatted = {}
      unformatted.each do |key, value|
        formatted[key.underscore.to_sym] = value ? value.gsub('http://schemas.google.com/g/2005#', '') : value
      end
      formatted[:primary] = unformatted['primary'] ? unformatted['primary'] == 'true' : false
      formatted
    end

    def format_phone_number(unformatted)
      unformatted[:number] = unformatted['$t']
      unformatted.delete '$t'
      format_email_or_phone unformatted
    end
    def format_email(unformatted)
      format_email_or_phone unformatted
    end
  end
end