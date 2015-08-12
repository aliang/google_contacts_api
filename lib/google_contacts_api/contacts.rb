# Module that implements a method to get contacts for a user or group
module GoogleContactsApi
  module Contacts
    # Retrieve the contacts for this user or group
    def get_contacts(params = {})
      # TODO: Should return empty ContactSet (haven't implemented one yet)
      return [] unless @api
      params = params.with_indifferent_access

      # compose params into a string
      # See http://code.google.com/apis/contacts/docs/3.0/reference.html#Parameters
      # alt, q, max-results, start-index, updated-min,
      # orderby, showdeleted, requirealldeleted, sortorder, group
      params["max-results"] = 100000 unless params.key?("max-results")
      url = "contacts/default/full"
      response = @api.get(url, params)
      
      # TODO: Define some fancy exceptions
      case GoogleContactsApi::Api.parse_response_code(response)
      when 401; raise
      when 403; raise
      when 404; raise
      when 400...500; raise
      when 500...600; raise
      end
      GoogleContactsApi::ContactSet.new(response.body, @api)
    end

    def get_contact(contact_id, params = {})
      Contact.new @api.get("contacts/default/full/#{contact_id}", params), @api
    end

    def update_contact(contact_id, params = {})
      get_contact(contact_id, params)
      etag = '*'

      @api.put(
          "contacts/default/base/#{contact_id}",
          params,
          headers: {
              :'If-Match' => etag
          },
          body: Nokogiri::XML::Builder.new do |xml|
            xml.entry 'gd:etag' => etag do
              xml.id "http://www.google.com/m8/feeds/contacts/default/base/#{contact_id}"
              xml.objects {
                @objects.each do |o|
                  xml.object(:type => o.type, :class => o.class, :id => o.id)
                end
              }
            end
          end.to_xml
      )
=begin
      <entry gd:etag="{lastKnownEtag}">
             <id>http://www.google.com/m8/feeds/contacts/{userEmail}/base/{contactId}</id>
  <updated>2008-02-28T18:47:02.303Z</updated>
      <category scheme="http://schemas.google.com/g/2005#kind"
      term="http://schemas.google.com/contact/2008#contact"/>
      <gd:name>
      <gd:givenName>New</gd:givenName>
    <gd:familyName>Name</gd:familyName>
      <gd:fullName>New Name</gd:fullName>
  </gd:name>
      <content type="text">Notes</content>
  <link rel="http://schemas.google.com/contacts/2008/rel#photo" type="image/*"
      href="https://www.google.com/m8/feeds/photos/media/{userEmail}/{contactId}"/>
      <link rel="self" type="application/atom+xml"
      href="https://www.google.com/m8/feeds/contacts/{userEmail}/full/{contactId}"/>
      <link rel="edit" type="application/atom+xml"
      href="https://www.google.com/m8/feeds/contacts/{userEmail}/full/{contactId}"/>
      <gd:phoneNumber rel="http://schemas.google.com/g/2005#other"
      primary="true">456-123-2133</gd:phoneNumber>
  <gd:extendedProperty name="pet" value="hamster"/>
      <gContact:groupMembershipInfo deleted="false"
      href="http://www.google.com/m8/feeds/groups/{userEmail}/base/{groupId}"/>
      </entry>
</pre>
=end
    end
  end
end