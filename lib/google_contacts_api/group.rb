module GoogleContactsApi
  # Represents a single group.
  class Group < GoogleContactsApi::Result
    include GoogleContactsApi::Contacts

    # Return true if this is a system group.
    def system_group?
      !self["gContact$systemGroup"].nil?
    end

    def system_group_id
      return unless self.system_group?
      self['gContact$systemGroup']['id']
    end

    # Return the contacts in this group and cache them.
    def contacts(params = {})
      # contacts in this group
      @contacts ||= get_contacts({"group" => self.id}.merge(params))
    end

    # Return the contacts in this group, retrieving them again from the server.
    def contacts!(params = {})
      # contacts in this group
      @contacts = nil
      contacts
    end

    # Returns the array of links, as link is an array for Hashie.
    def links
      self["link"].map { |l| l.href }
    end

    def self_link
      _link = self["link"].find { |l| l.rel == "self" }
      _link ? _link.href : nil
    end

    def edit_link
      _link = self["link"].find { |l| l.rel == "edit" }
      _link ? _link.href : nil
    end

    def delete(api)
      api.delete(id_path, {}, 'If-Match' => etag)
    end

    def self.create(api, title)
      response = api.post('groups/default/full', xml_for_create(title), {}, 'Content-Type' => 'application/atom+xml')
      Group.new(Hashie::Mash.new(JSON.parse(response.body)).entry)
    end

    def self.xml_for_create(title)
      '<atom:entry xmlns:gd="http://schemas.google.com/g/2005" '\
        'xmlns:atom="http://www.w3.org/2005/Atom">'\
        '<atom:category scheme="http://schemas.google.com/g/2005#kind" '\
          'term="http://schemas.google.com/contact/2008#group"/>'\
        '<atom:title type="text">' +
        title.to_s.encode(xml: :text) + 
        '</atom:title>'\
      '</atom:entry>'
    end
  end
end
