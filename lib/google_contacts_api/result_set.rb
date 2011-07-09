require 'json'

module GoogleContactsApi
  # Base class for GroupSet and ContactSet
  class ResultSet
    include Enumerable
    attr_reader :api
    attr_accessor :total_results, :start_index, :items_per_page, :parsed
    
    # Initialize a new ResultSet from the response, with the given
    # GoogleContacts::Api object if specified.
    def initialize(response_body, api = nil)
      @api = api
      @parsed = Hashie::Mash.new(JSON.parse(response_body))
      @total_results = @parsed.feed["openSearch$totalResults"]["$t"].to_i
      @start_index = @parsed.feed["openSearch$startIndex"]["$t"].to_i
      @items_per_page = @parsed.feed["openSearch$itemsPerPage"]["$t"].to_i
      @results = []
    end
    
    # Yields to block for each result
    def each
      @results.each { |x| yield x }
    end
    
    # Return true if there are more results with the same
    # parameters you used
    def has_more?
      # 1-based indexing
      @start_index - 1 + @items_per_page <= @total_results
    end
    
    def inspect #:nodoc:
      "<#{self.class}: @start_index=#{@start_index}, @items_per_page=#{@items_per_page}, @total_results=#{@total_results}>"
    end
  end
end