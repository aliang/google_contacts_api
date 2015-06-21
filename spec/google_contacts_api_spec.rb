require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MockOAuth2Error < StandardError
  attr_accessor :response
  
  def initialize(response)
    @response = response
  end
end

describe "GoogleContactsApi" do
  describe "Api" do
    before(:each) do
      @oauth = double("oauth")
      allow(@oauth).to receive(:get).and_return("get response")
      @api = GoogleContactsApi::Api.new(@oauth)
    end

    describe ".get" do
      it "should perform a get request using oauth returning json with version 3" do
        # expectation should come before execution
        expect(@oauth).to receive(:get).with(
          GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3", {"header" => "header"})
        expect(@api.get("any_url",
          {"param" => "param"},
          {"header" => "header"})).to eq("get response")
      end

      it "should perform a get request using oauth with the version specified" do
        expect(@oauth).to receive(:get).with(
          GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=2", {"header" => "header"})
        expect(@api.get("any_url",
          {"param" => "param", "v" => "2"},
          {"header" => "header"})).to eq("get response")
      end
    end

    # Not implemented yet
    pending "should perform a post request using oauth"
    pending "should perform a put request using oauth"
    pending "should perform a delete request using oauth"
    # Not sure how to test, you'd need a revoked token.
    it "should raise UnauthorizedError if OAuth 1.0 returns unauthorized" do
      oauth = double("oauth")
      error_html = load_file(File.join('errors', 'auth_sub_401.html'))
      allow(oauth).to receive(:get).and_return(Net::HTTPUnauthorized.new("1.1", 401, error_html))
      api = GoogleContactsApi::Api.new(oauth)
      expect { api.get("any url",
        {"param" => "param"},
        {"header" => "header"}) }.to raise_error(GoogleContactsApi::UnauthorizedError)
    end
    
    it "should raise UnauthorizedError if OAuth 2.0 returns unauthorized" do
      oauth = double("oauth2")
      oauth2_response = Struct.new(:status)
      allow(oauth).to receive(:get).and_raise(MockOAuth2Error.new(oauth2_response.new(401)))
      api = GoogleContactsApi::Api.new(oauth)
      expect { api.get("any url",
        {"param" => "param"},
        {"header" => "header"}) }.to raise_error(GoogleContactsApi::UnauthorizedError)
    end
    
    describe "parsing response code" do
      before(:all) do
        @Oauth = Struct.new(:code)
        @Oauth2 = Struct.new(:status)
      end
      it "should parse something that looks like an oauth gem response" do
        expect(GoogleContactsApi::Api.parse_response_code(@Oauth.new("401"))).to eq(401)
      end

      it "should parse something that looks like an oauth2 gem response" do
        expect(GoogleContactsApi::Api.parse_response_code(@Oauth2.new(401))).to eq(401)
      end
    end
  end

  describe GoogleContactsApi::Contacts do
    let(:api) { double("api") }
    let(:test_class) {
      Class.new do
        include GoogleContactsApi::Contacts
        def initialize(api)
          @api = api
        end
      end
    }
    describe ".get_contacts" do
      it "should get the contacts using the internal @api object" do
        expect(api).to receive(:get).with("contacts/default/full", kind_of(Hash)).and_return(Hashie::Mash.new({
          "body" => "some response", # could use example response here
          "code" => 200
        }))
        allow(GoogleContactsApi::ContactSet).to receive(:new).and_return("contact set")
        expect(test_class.new(api).get_contacts).to eq("contact set")
      end
    end
  end

  describe GoogleContactsApi::Groups do
    let(:api) { double("api") }
    let(:test_class) {
      Class.new do
        include GoogleContactsApi::Groups
        def initialize(api)
          @api = api
        end
      end
    }
    describe ".get_groups" do
      it "should get the groups using the internal @api object" do
        expect(api).to receive(:get).with("groups/default/full", kind_of(Hash)).and_return(Hashie::Mash.new({
          "body" => "some response", # could use example response here
          "code" => 200
        }))
        allow(GoogleContactsApi::GroupSet).to receive(:new).and_return("group set")
        expect(test_class.new(api).get_groups).to eq("group set")
      end
    end
  end

  describe GoogleContactsApi::User do
    let(:oauth) { double ("oauth") }
    let(:user) { GoogleContactsApi::User.new(@oauth) }

    # Should hit the right URLs and return the right stuff
    describe ".groups" do
      it "should be able to get groups including system groups" do
        expect(user).to receive(:get_groups).and_return("group set")
        expect(user.groups).to eq("group set")
      end
    end
    describe ".groups!" do
      it "should be able to get groups" do
        expect(user).to receive(:get_groups).and_return("group set")
        expect(user.groups!).to eq("group set")
      end
      it "should pass query params along to get_groups" do
        expect(user).to receive(:get_groups).with("something" => "important").and_return("group set")
        expect(user.groups!("something" => "important")).to eq("group set")
      end
      it "should reload the groups" do
        expect(user).to receive(:get_groups).and_return("group set").twice
        user.groups
        groups = user.groups!
        expect(groups).to eq("group set")
      end
    end
    describe ".contacts" do
      it "should be able to get contacts" do
        expect(user).to receive(:get_contacts).and_return("contact set")
        expect(user.contacts).to eq("contact set")
      end
      it "should use the contact cache for subsequent access" do
        expect(user).to receive(:get_contacts).and_return("contact set").once
        user.contacts
        contacts = user.contacts
        expect(contacts).to eq("contact set")
      end
    end
    describe ".contacts!" do
      it "should be able to get contacts" do
        expect(user).to receive(:get_contacts).and_return("contact set")
        expect(user.contacts!).to eq("contact set")
      end
      it "should pass query params along to get_contacts" do
        expect(user).to receive(:get_contacts).with("something" => "important").and_return("contact set")
        expect(user.contacts!("something" => "important")).to eq("contact set")
      end
      it "should reload the contacts" do
        expect(user).to receive(:get_contacts).and_return("contact set").twice
        user.contacts
        contacts = user.contacts!
        expect(contacts).to eq("contact set")
      end
    end
  end

  describe "ResultSet" do
    pending ".each"
    pending ".has_more?"
  end

  describe "ContactSet" do
    describe "with entries" do
      before(:all) do
        @contact_set_json = contact_set_json
        @contact_set = GoogleContactsApi::ContactSet.new(@contact_set_json)
      end

      it "should return the right starting index" do
        expect(@contact_set.start_index).to eq(1)
      end
      it "should return the right number of results per page" do
        expect(@contact_set.items_per_page).to eq(25)
      end
      it "should return the right number of total results" do
        expect(@contact_set.total_results).to eq(500)
      end
      it "should tell me if there are more results" do
        # yeah this is an awkward assertion and matcher
        expect(@contact_set).to be_has_more
        expect(@contact_set.has_more?).to eq(true)
      end
      it "should parse results into Contacts" do
        expect(@contact_set.to_a.first).to be_instance_of(GoogleContactsApi::Contact)
      end
    end
    it "should parse nil results into an empty array" do
      @empty_contact_set_json = empty_contact_set_json
      @empty_contact_set = GoogleContactsApi::ContactSet.new(@empty_contact_set_json)
      expect(@empty_contact_set.total_results).to eq(0)
      expect(@empty_contact_set.instance_variable_get("@results")).to eq([])
    end
  end

  describe "GroupSet" do
    before(:all) do
      @group_set_json = group_set_json
      @group_set = GoogleContactsApi::GroupSet.new(@group_set_json)
    end

    it "should return the right starting index" do
      expect(@group_set.start_index).to eq(1)
    end
    it "should return the right number of results per page" do
      expect(@group_set.items_per_page).to eq(25)
    end
    it "should return the right number of total results" do
      expect(@group_set.total_results).to eq(5)
    end
    it "should tell me if there are more results" do
      # yeah this is an awkward assertion and matcher
      expect(@group_set).not_to be_has_more
      expect(@group_set.has_more?).to eq(false)
    end
    it "should parse results into Groups" do
      expect(@group_set.to_a.first).to be_instance_of(GoogleContactsApi::Group)
    end
  end

  describe "Result" do
    it 'supports the deleted? method' do
      expect(GoogleContactsApi::Result.new('gd$deleted' => {}).deleted?).to eq(true)
      expect(GoogleContactsApi::Result.new.deleted?).to eq(false)
    end
  end

  describe "Contact" do
    before(:all) do
      @contact_json_hash = contact_json_hash
      @contact = GoogleContactsApi::Contact.new(@contact_json_hash)
    end
    # ok, these tests are kind of silly
    it "should return the right title" do
      expect(@contact.title).to eq("Contact 1")
    end
    it "should return the right id" do
      expect(@contact.id).to eq("http://www.google.com/m8/feeds/contacts/example%40gmail.com/base/0")
    end
    it "should return the right content" do
      # TODO: Nothing in source, oops
      expect(@contact.content).to eq(nil)
    end
    it "should return the right updated time" do
      # different representation slightly
      expect(@contact.updated.to_s).to eq("2011-07-07T21:02:42+00:00")
    end
    it "should return the right self link" do
      expect(@contact.self_link).to eq("https://www.google.com/m8/feeds/contacts/example%40gmail.com/full/0")
    end
    it "should return the right photo link entry" do
      expect(@contact.photo_link_entry).to eq({
        "rel" => "http://schemas.google.com/contacts/2008/rel#photo",
        "type" => "image/*",
        "href" => "https://www.google.com/m8/feeds/photos/media/example%40gmail.com/0",
        "gd$etag" => "\"dxt2DAEZfCp7ImA-AV4zRxBoPG4UK3owXBM.\""
      })
    end
    it "should return the right photo link" do
      expect(@contact.photo_link).to eq("https://www.google.com/m8/feeds/photos/media/example%40gmail.com/0")
    end
    it "should return the right edit link" do
      expect(@contact.edit_link).to eq("https://www.google.com/m8/feeds/contacts/example%40gmail.com/full/0")
    end
    it "should return the right edit photo link" do
      # TODO: there isn't one in this contact, hahah
      expect(@contact.edit_photo_link).to eq(nil)
    end
    it "should try to fetch a photo" do
      @oauth = double("oauth")
      allow(@oauth).to receive(:get).and_return(Hashie::Mash.new({
        "body" => "some response", # could use example response here
        "code" => 200
      }))
      # @api = GoogleContactsApi::Api.new(@oauth)
      @api = double("api")
      allow(@api).to receive(:oauth).and_return(@oauth)
      @contact = GoogleContactsApi::Contact.new(@contact_json_hash, nil, @api)
      expect(@oauth).to receive("get").with(@contact.photo_link)
      @contact.photo
    end
    it "should fetch a photo with metadata" do
      @oauth = double("oauth")
      allow(@oauth).to receive(:get).and_return(Hashie::Mash.new({
         "body" => "some response",
         "code" => 200,
         "headers" => { "content-type" => "image/jpeg" }
       }))
      @api = double("api")
      allow(@api).to receive(:oauth).and_return(@oauth)
      @contact = GoogleContactsApi::Contact.new(@contact_json_hash, nil, @api)
      expect(@oauth).to receive("get").with(@contact.photo_link)
      expect(@contact.photo_with_metadata).to eq( { data: 'some response',
                                                    etag: 'dxt2DAEZfCp7ImA-AV4zRxBoPG4UK3owXBM.',
                                                    content_type: 'image/jpeg'
                                                  } )
    end
    # TODO: there isn't any phone number in here
    pending "should return all phone numbers"
    it "should return all e-mail addresses" do
      expect(@contact.emails).to eq(["contact1@example.com"])
    end
    it "should return the right primary e-mail address" do
      expect(@contact.primary_email).to eq("contact1@example.com")
    end
    it "should return an empty array if there are no e-mail addresses" do
      @contact = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
      expect(@contact.emails).to eq([])
    end
    it "should return nil if there is no primary e-mail address" do
      @contact2 = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
      expect(@contact2.primary_email).to be_nil
      @contact3 = GoogleContactsApi::Contact.new(contact_no_primary_email_json_hash)
      expect(@contact3.primary_email).to be_nil
    end
    it "should return all instant messaging accounts" do
      expect(@contact.ims).to eq(["contact1@example.com"])
    end
    it "should return an empty array if there are no instant messaging accounts" do
      @contact = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
      expect(@contact.ims).to eq([])
    end

    #
    describe 'Contacts API v3 fields' do
      before do
        @empty = GoogleContactsApi::Contact.new

        @partly_empty = GoogleContactsApi::Contact.new(
          'gd$name' => {},
          'gContact$relation' => []        
        )

        @contact_v3 = GoogleContactsApi::Contact.new(
          'gd$name' => {
            'gd$givenName' => { '$t' => 'John' },
            'gd$familyName' => { '$t' => 'Doe' },
            'gd$fullName' => { '$t' => 'John Doe' }
          },
          'gContact$birthday' => {
            'when' => '1988-05-12'
          },
          'gContact$relation' => [ { '$t' => 'Jane', 'rel' => 'spouse' } ],
          'gd$structuredPostalAddress' => [
            {
              'gd$country' => { '$t' => 'United States of America' },
              'gd$formattedAddress' => { '$t' => "2345 Long Dr. #232\nSomwhere\nIL\n12345\nUnited States of America" },
              'gd$city' => { '$t' => 'Somwhere' },
              'gd$street' => { '$t' => '2345 Long Dr. #232' },
              'gd$region' => { '$t' => 'IL' },
              'gd$postcode' => { '$t' => '12345' }
            },
            {
              'rel' => 'http://schemas.google.com/g/2005#home',
              'primary' => 'true',
              'gd$country' => { '$t' => 'United States of America' },
              'gd$formattedAddress' => { '$t' => "123 Far Ln.\nAnywhere\nMO\n67891\nUnited States of America" },
              'gd$city' => { '$t' => 'Anywhere' },
              'gd$street' => { '$t' => '123 Far Ln.' }
            }
          ],
          'gd$email' => [
            {
              'primary' => 'true',
              'rel' => 'http://schemas.google.com/g/2005#other',
              'address' => 'johnsmith@example.com'
            }
          ],
          'gd$phoneNumber' => [
            {
              'primary' => 'true',
              '$t' => '(123) 334-5158',
              'rel' => 'http://schemas.google.com/g/2005#mobile'
            }
          ],
          'gd$organization' => [
            {
              'gd$orgTitle' => { '$t' => 'Worker Person' },
              'gd$orgName' => { '$t' => 'Example, Inc' },
              'rel' => 'http://schemas.google.com/g/2005#other'
            }
          ],
          'gContact$groupMembershipInfo' => [
            {
              'deleted' => 'false',
              'href' => 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/111'
            },
            {
              'deleted' => 'true',
              'href' => 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/222'
            }
          ]
        )
      end

      it 'should catch nil values for nested fields' do
        expect(@empty.nested_t_field_or_nil('gd$name', 'gd$givenName')).to be_nil
        expect(@partly_empty.nested_t_field_or_nil('gd$name', 'gd$givenName')).to be_nil
        expect(@contact_v3.nested_t_field_or_nil('gd$name', 'gd$givenName')).to eq('John')
      end

      it 'has given_name' do
        expect(@contact_v3.given_name).to eq('John')
      end

      it 'has family_name' do
        expect(@contact_v3.family_name).to eq('Doe')
      end

      it 'has full_name' do
        expect(@contact_v3).to receive(:nested_t_field_or_nil).with('gd$name', 'gd$fullName').and_return('val')
        expect(@contact_v3.full_name).to eq('val')
      end

      it 'has relations' do
        expect(@empty.relations).to eq([])
        expect(@partly_empty.relations).to eq([])
        expect(@contact_v3.relations).to eq([ { '$t' => 'Jane', 'rel' => 'spouse' } ])
      end
      it 'has spouse' do
        expect(@empty.spouse).to be_nil
        expect(@partly_empty.spouse).to be_nil
        expect(@contact_v3.spouse).to eq('Jane')
      end

      it 'has birthday' do
        expect(@empty.birthday).to be_nil
        expect(@contact_v3.birthday).to eq({ year: 1988, month: 5, day: 12 })

        contact_birthday_no_year = GoogleContactsApi::Contact.new('gContact$birthday' => { 'when' => '--05-12' })
        expect(contact_birthday_no_year.birthday).to eq({ year: nil, month: 5, day: 12 })
      end
      
      it 'has addresses' do
        expect(@empty.addresses).to eq([])

        formatted_addresses = [
          { rel: 'work', primary: false, country: 'United States of America', city: 'Somwhere', street: '2345 Long Dr. #232',
            region: 'IL', postcode: '12345' },
          { rel: 'home', primary: true, country: 'United States of America', city: 'Anywhere', street: '123 Far Ln.',
            region: nil, postcode: nil }
        ]
        expect(@contact_v3.addresses).to eq(formatted_addresses)
      end

      it 'has full phone numbers' do
        expect(@empty.phone_numbers_full).to eq([])
        expect(@contact_v3.phone_numbers_full).to eq([ { :primary => true, :number => '(123) 334-5158', :rel => 'mobile' } ])
      end
      it 'has full emails' do
        expect(@empty.emails_full).to eq([])
        expect(@contact_v3.emails_full).to eq([ { :primary => true, :address => 'johnsmith@example.com', :rel => 'other' } ])
      end

      it 'has organizations' do
        expect(@empty.organizations).to eq([])

        formatted_organizations = [
          {
            org_title: 'Worker Person',
            org_name: 'Example, Inc',
            primary: false,
            rel: 'other'
          }
        ]
        expect(@contact_v3.organizations).to eq(formatted_organizations)
      end

      it 'has group membership info' do
        expect(@empty.group_membership_info).to eq([])

        group_membership_info = [
          { deleted: false, href: 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/111' },
          { deleted: true, href: 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/222' }
        ]
        expect(@contact_v3.group_membership_info).to eq(group_membership_info)
      end

      it 'has group memberships' do
        expect(@contact_v3.group_memberships).to eq(['http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/111'])
      end

      it 'has deleted group memberships' do
        expect(@contact_v3.deleted_group_memberships).to eq(['http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/222'])
      end
    end

    # The Google Contacts API (https://developers.google.com/gdata/docs/2.0/elements)
    # specifies an optional yomi field for orgName, givenName, additionalName and familyName
    it 'handles Japanese yomigana "yomi" name values' do
      contact_params = {
        'gd$name' => {
          'gd$givenName' => {'$t' => 'John' },
          'gd$additionalName' => {'$t' => 'Text name', 'yomi' => 'And yomi chars' },
          'gd$familyName' => { 'yomi' => 'Yomi chars only' },
        },
        'gd$organization' => [{
          'rel' => 'http://schemas.google.com/g/2005#other',
          'primary' => 'true',
          'gd$orgName' => {
            'yomi' => 'Japanese yomigana'
          }
        }],
      }
      contact = GoogleContactsApi::Contact.new(contact_params, nil, @api)
      expect(contact.given_name).to eq('John')
      expect(contact.additional_name).to eq('Text name')
      expect(contact.family_name).to eq('Yomi chars only')
      expect(contact.organizations.first[:org_name]).to eq('Japanese yomigana')
    end
  end

  describe GoogleContactsApi::Group do
    before(:all) do
      @group_json_hash = group_json_hash
      @group = GoogleContactsApi::Group.new(group_json_hash)
    end
    # ok, these tests are kind of silly
    it "should return the right title" do
      expect(@group.title).to eq("System Group: My Contacts")
    end
    it "should return the right id" do
      expect(@group.id).to eq("http://www.google.com/m8/feeds/groups/example%40gmail.com/base/6")
    end
    it "should return the right content" do
      # TODO: Nothing in source, oops
      expect(@group.content).to eq("System Group: My Contacts")
    end
    it "should return the right updated time" do
      # different representation slightly
      expect(@group.updated.to_s).to eq("1970-01-01T00:00:00+00:00")
    end
    it "should tell me if it's a system group" do
      expect(@group).to be_system_group
    end
    it 'tells the system group id or nil if not a system group' do
      expect(@group).to be_system_group
      expect(@group.system_group_id).to eq('Contacts')

      @group.delete('gContact$systemGroup')
      expect(@group).to_not be_system_group
      expect(@group.system_group_id).to be_nil
    end
    describe ".contacts" do
      before(:each) do
        @api = double("api")
        @group = GoogleContactsApi::Group.new(@contact_json_hash, nil, @api)
        allow(@group).to receive(:id).and_return("group id")
      end
      it "should be able to get contacts" do
        expect(@group).to receive(:get_contacts).with(hash_including({"group" => "group id"})).and_return("contact set")
        expect(@group.contacts).to eq("contact set")
      end
      it "should use the contact cache for subsequent access" do
        expect(@group).to receive(:get_contacts).with(hash_including({"group" => "group id"})).and_return("contact set").once
        @group.contacts
        contacts = @group.contacts
        expect(contacts).to eq("contact set")
      end
    end
    describe ".contacts!" do
      before(:each) do
        @api = double("api")
        @group = GoogleContactsApi::Group.new(@contact_json_hash, nil, @api)
        allow(@group).to receive(:id).and_return("group id")
      end
      it "should be able to get contacts" do
        expect(@group).to receive(:get_contacts).with(hash_including({"group" => "group id"})).and_return("contact set")
        expect(@group.contacts!).to eq("contact set")
      end
      it "should use the contact cache for subsequent access" do
        expect(@group).to receive(:get_contacts).with(hash_including({"group" => "group id"})).and_return("contact set").twice
        @group.contacts
        contacts = @group.contacts!
        expect(contacts).to eq("contact set")
      end
    end
  end
end
