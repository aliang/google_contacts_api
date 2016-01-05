module GoogleContactsApi
  class GroupSet < GoogleContactsApi::ResultSet
    # Initialize a GroupSet from an API response body that contains groups data
    def initialize(response_body, api = nil)
      super
      if @parsed.nil? || @parsed.feed.nil? || @parsed.feed.entry.nil?
        @results = []
      else
        @results = @parsed.feed.entry.map { |e| GoogleContactsApi::Group.new(e, nil, api) }
      end
    end
  end
end
