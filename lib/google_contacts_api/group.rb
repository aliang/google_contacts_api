module GoogleContactsApi
  # Represents a single group.
  class Group < GoogleContactsApi::Result
    include GoogleContactsApi::Contacts

    # Return true if this is a system group.
    def system_group?
      !self["gContact$systemGroup"].nil?
    end

    def system_group_id
      return nil unless system_group?
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

    def self.create(attrs, api)
      response = api.post('groups/default/full', xml_for_create(attrs), {}, 'Content-Type' => 'application/atom+xml')
      Group.new(Hashie::Mash.new(JSON.parse(response.body)).entry)
    end

    def self.xml_for_create(group_attrs)
      @@new_group_template ||= File.new(File.dirname(__FILE__) + '/templates/group.xml.erb').read
      action = :create
      ERB.new(@@new_group_template).result(binding)
    end
  end
end