# TODO: Use more than one file

require 'active_support/core_ext'
require 'json'
require 'hashie'

module GoogleContactsApi
  class Api
    # keep separate in case of new auth method
    BASE_URL = "https://www.google.com/m8/feeds/"

    attr_reader :oauth
    def initialize(oauth)
      # TODO: Later, accept ClientLogin
      @oauth = oauth
    end

    # Get request to specified link, with query params
    # For get, post, put, delete, always use JSON, it's simpler
    # and lets us use Hashie::Mash. Note that in the JSON conversion from XML,
    # ":" is replaced with $, element content is keyed with $t
    def get(link, params = {}, headers = {})
      params["alt"] = "json"
      @oauth.get("#{BASE_URL}#{link}?#{params.to_query}", headers)
    end

    # Post request to specified link, with query params
    # Not tried yet, might be issues with params
    def post(link, params = {}, headers = {})
      params["alt"] = "json"
      @oauth.post("#{BASE_URL}#{link}?#{params.to_query}", headers)
    end

    # Put request to specified link, with query params
    # Not tried yet
    def put(link, params = {}, headers = {})
      params["alt"] = "json"
      @oauth.put("#{BASE_URL}#{link}?#{params.to_query}", headers)
    end

    # Delete request to specified link, with query params
    # Not tried yet
    def delete(link, params = {}, headers = {})
      params["alt"] = "json"
      @oauth.delete("#{BASE_URL}#{link}?#{params.to_query}", headers)
    end
  end

  module Contacts
    # Retrieve the contacts for this user or group
    def contacts(params = {})
      params = params.with_indifferent_access

      # compose params into a string
      # See http://code.google.com/apis/contacts/docs/3.0/reference.html#Parameters
      # alt, q, max-results, start-index, updated-min,
      # orderby, showdeleted, requirealldeleted, sortorder, group
      params["max-results"] = 100000 unless params.key?("max-results")
      url = "contacts/default/full"
      response = @api.get(url, params)
      
      # TODO: Define some fancy exceptions
      case response.code
      when 401; raise
      when 403; raise
      when 404; raise
      when 400...500; raise
      when 500...600; raise
      end
      ContactSet.new(response.body, @api)
    end
  end

  class User
    include Contacts
    
    attr_reader :api
    def initialize(oauth)
      @api = GoogleContactsApi::Api.new(oauth)
    end

    # Retrieve the groups for this user
    # TODO: Handle 403, 404, 401
    def groups(params = {})
      params = params.with_indifferent_access
      # compose params into a string
      # See http://code.google.com/apis/contacts/docs/3.0/reference.html#Parameters
      # alt, q, max-results, start-index, updated-min,
      # orderby, showdeleted, requirealldeleted, sortorder
      params["max-results"] = 100000 unless params.key?("max-results")
      url = "groups/default/full"
      # TODO: So weird thing, version 3 doesn't return system groups
      # When it does, uncomment this line and use it to request instead
      # response = @api.get(url, params)
      response = @api.get(url, params, {"GData-Version" => "2"})

      case response.code
      when 401; raise
      when 403; raise
      when 404; raise
      when 400...500; raise
      when 500...600; raise
      end
      GroupSet.new(response.body, @api)
    end
  end

  # Base class for GroupSet and ContactSet
  class ResultSet
    include Enumerable
    attr_reader :api
    attr_accessor :total_results, :start_index, :items_per_page, :parsed
    
    def initialize(response_body, api = nil)
      @api = api
      @parsed = Hashie::Mash.new(JSON.parse(response_body))
      @total_results = @parsed.feed["openSearch$totalResults"]["$t"].to_i
      @start_index = @parsed.feed["openSearch$startIndex"]["$t"].to_i
      @items_per_page = @parsed.feed["openSearch$itemsPerPage"]["$t"].to_i
      @results = []
    end
    
    def each
      @results.each { |x| yield x }
    end
    
    def has_more?
      # 1-based indexing
      @start_index - 1 + @items_per_page <= @total_results
    end
    
    def inspect
      "<#{self.class}: @start_index=#{@start_index}, @items_per_page=#{@items_per_page}, @total_results=#{@total_results}>"
    end
  end

  class GroupSet < ResultSet
    # Populate from a response that contains contacts
    def initialize(response_body, api = nil)
      super
      @results = @parsed.feed.entry.map { |e| Group.new(e, nil, api) }
    end
  end

  class ContactSet < ResultSet
    # Populate from a response that contains contacts
    def initialize(response_body, api = nil)
      super
      @results = @parsed.feed.entry.map { |e| Contact.new(e, nil, api) }
    end
  end

  # Base class for Group and Contact
  class Result < Hashie::Mash
    # Note that the title is really just the (full) name
    # ":" replaced with $, element content is keyed with $t
    
    # These are the accessors we can write
    # :id, :title, :updated, :content
    
    attr_reader :api
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
      _content ? content["$t"] : nil
    end
    
    def updated
      _updated = self["updated"]
      _updated ? DateTime.parse(_updated["$t"]) : nil
    end
    
    # Returns the array of categories, as category is an array for Hashie.
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

  class Group < Result
    include Contacts
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

  class Contact < Result
    # :categories, (:content again), :links, (:title again), :email
    # :extended_properties, :deleted, :im, :name,
    # :organizations, :phone_numbers, :structured_postal_addresses, :where
    
    # Returns the array of links, as link is an array for Hashie.
    def links
      self["link"].map { |l| l.href }
    end
    
    def self_link
      _link = self["link"].find { |l| l.rel == "self" }
      _link ? _link.href : nil
    end
    
    def alternate_link
      _link = self["link"].find { |l| l.rel == "alternate" }
      _link ? _link.href : nil
    end
    
    def photo_link
      _link = self["link"].find { |l| l.rel == "http://schemas.google.com/contacts/2008/rel#photo" }
      _link ? _link.href : nil
    end
    
    # Returns binary data for the photo. You can probably
    # use it in a data-uri. This is in PNG format.
    def photo
      return nil unless photo_link
      response = @api.oauth.get(photo_link)
      
      case response.code
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
    
    def edit_photo_link
      _link = self["link"].find { |l| l.rel == "http://schemas.google.com/contacts/2008/rel#edit_photo" }
      _link ? _link.href : nil
    end
    
    def edit_link
      _link = self["link"].find { |l| l.rel == "edit" }
      _link ? _link.href : nil
    end
    
    def emails
      self["gd$email"].map { |e| e.address }
    end
    
    def primary_email
      _email = self["gd$email"].find { |e| e.primary == "true" }
      _email ? _email.address : nil
    end
  end
end