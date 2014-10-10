require 'hashie'

module GoogleContactsApi
  # Base class for Group and Contact
  class Result < Hashie::Mash
    # Note that the title is really just the (full) name
    # ":" replaced with $, element content is keyed with $t
    
    # These are the accessors we can write
    # :id, :title, :updated, :content
    
    attr_accessor :api
    # Populate from a single result Hash/Hashie
    def initialize(source_hash = nil, default = nil, api = nil, &blk)
      @api = api if api
      super(source_hash, default, &blk)
    end

    # TODO: Conditional retrieval? There might not be an etag in the
    # JSON representation, there is in the XML representation
    def etag
    end

    def id
      _id = self["id"]
      _id ? _id["$t"] : nil
    end
    
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
      raise NotImplementedError
    end
    
    def inspect
      "<#{self.class}: #{title}>"
    end
  end
end