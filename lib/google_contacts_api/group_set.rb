module GoogleContactsApi
  class GroupSet < GoogleContactsApi::ResultSet
    # Initialize a GroupSet from an API response body that contains groups data
    def initialize(response_body, api = nil)
      super
      @results = @parsed.feed.entry.map { |e| GoogleContactsApi::Group.new(e, nil, api) }
    end
  end
end