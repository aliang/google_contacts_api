# Module that implements a method to get groups for a user
module GoogleContactsApi
  module Groups
    # Retrieve the contacts for this user or group
    def get_groups(params = {})
      params = params.with_indifferent_access
      # compose params into a string
      # See http://code.google.com/apis/contacts/docs/3.0/reference.html#Parameters
      # alt, q, max-results, start-index, updated-min,
      # orderby, showdeleted, requirealldeleted, sortorder
      params["max-results"] = 100000 unless params.key?("max-results")

      url = "groups/default/full"
      response = @api.get(url, params)

      case GoogleContactsApi::Api.parse_response_code(response)
      # TODO: Better handle 401, 403, 404
      when 401; raise
      when 403; raise
      when 404; raise
      when 400...500; raise
      when 500...600; raise
      end
      GoogleContactsApi::GroupSet.new(response.body, @api)
    end

    # Create and return a group
    def create_group(title)
      response = @api.post('groups/default/full', create_group_xml(title), {},
                          'Content-Type' => 'application/atom+xml')
      Group.new(Hashie::Mash.new(JSON.parse(response.body)).entry)
    end

    def delete_group(group)
      @api.delete(group.id_path, {}, 'If-Match' => group.etag)
    end

    private

    def create_group_xml(title)
      <<-EOS
      <atom:entry xmlns:gd="http://schemas.google.com/g/2005"
        xmlns:atom="http://www.w3.org/2005/Atom">
        <atom:category scheme="http://schemas.google.com/g/2005#kind"
          term="http://schemas.google.com/contact/2008#group"/>
        <atom:title type="text">#{title.to_s.encode(xml: :text)}</atom:title>
      </atom:entry>
      EOS
    end
  end
end
