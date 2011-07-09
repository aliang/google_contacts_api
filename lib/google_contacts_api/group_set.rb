module GoogleContactsApi
  class GroupSet < GoogleContactsApi::ResultSet
    # Populate from a response that contains contacts
    def initialize(response_body, api = nil)
      super
      @results = @parsed.feed.entry.map { |e| GoogleContactsApi::Group.new(e, nil, api) }
    end
  end
end