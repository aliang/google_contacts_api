require 'hashie'

module GoogleContactsApi
  # Base class for Group and Contact.
  # In the JSON responses, ":" from the equivalent XML response is replaced
  # with a "$", while element content is instead keyed with "$t".
  class Result < Hashie::Mash
    attr_reader :api
    # Initialize a Result from a single result's Hash/Hashie
    def initialize(source_hash = nil, default = nil, api = nil, &blk)
      @api = api if api
      super(source_hash, default, &blk)
    end

    def etag
      self['gd$etag']
    end

    def id
      _id = self["id"]
      _id ? _id["$t"] : nil
    end

    # Item path relative to Google contacts URL base for puts/posts/deletes
    def id_path
      id.sub('http://', 'https://')
        .sub(GoogleContactsApi::Api::BASE_URL, '').sub('/base/', '/full/')
    end

    # For Contacts, returns the (full) name.
    # For Groups, returns the name of the group.
    def title
      _title = self["title"]
      _title ? _title["$t"] : nil
    end

    def content
      _content = self["content"]
      _content ? _content["$t"] : nil
    end

    def updated
      _updated = self["updated"]
      _updated ? DateTime.parse(_updated["$t"]) : nil
    end

    # Returns the array of categories, as category is an array for Hashie.
    # There is a scheme and a term.
    def categories
      category
    end

    def deleted?
      self.key?('gd$deleted')
    end

    def inspect
      "<#{self.class}: #{title}>"
    end
  end
end
