module GoogleContactsApi
  class Group < GoogleContactsApi::Result
    include GoogleContactsApi::Contacts
    # Populate from a single entry element in the result response
    # when requesting a set of Contacts

    def system_group?
      !self["gContact$systemGroup"].nil?
    end

    def contacts(params = {})
      # contacts in this group
      @contacts ||= super({"group" => self.id}.merge(params))
    end
    
    def contacts!(params = {})
      # contacts in this group
      @contacts = super({"group" => self.id}.merge(params))
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
  end
end