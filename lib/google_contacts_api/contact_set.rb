module GoogleContactsApi
  # Represents a set of contacts.
  class ContactSet < GoogleContactsApi::ResultSet
    # Initialize a ContactSet from an API response body that contains contacts data
    def initialize(response_body, api = nil)
      super
      if @parsed.nil? || @parsed.feed.nil? || @parsed.feed.entry.nil?
        @results = []
      else
        @results = @parsed.feed.entry.map { |e| GoogleContactsApi::Contact.new(e, nil, api) }
      end
    end
  end
end