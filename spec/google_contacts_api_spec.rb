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
      @api = GoogleContactsApi::Api.new(@oauth)
    end

    describe ".get" do
      it "should perform a get request using oauth returning json with version 3" do
        # expectation should come before execution
        expect(@oauth).to receive(:request)
                          .with(:get, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3", headers: {"header" => "header"})
                          .and_return('get response')
        expect(@api.get("any_url",
                        {"param" => "param"},
                        {"header" => "header"})).to eq("get response")
      end

      it "should perform a get request using oauth with the version specified" do
        expect(@oauth).to receive(:request)
                          .with(:get, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=2", headers: {"header" => "header"})
                          .and_return('get response')
        expect(@api.get("any_url",
                        {"param" => "param", "v" => "2"},
                        {"header" => "header"})).to eq("get response")
      end
    end

    it "should perform a post request using oauth" do
      expect(@oauth).to receive(:request)
                        .with(:post, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
                              body: 'body', headers: {"header" => "header"})
                        .and_return('get response')
      expect(@api.post("any_url", 'body', {"param" => "param"}, {"header" => "header"})).to eq("get response")
    end

    it "should perform a put request using oauth" do
      expect(@oauth).to receive(:request)
                        .with(:put, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
                              body: 'body', headers: {"header" => "header"})
                        .and_return('get response')
      expect(@api.put("any_url", 'body', {"param" => "param"}, {"header" => "header"})).to eq("get response")
    end

    it "should perform a delete request using oauth" do
      expect(@oauth).to receive(:request)
                        .with(:delete, GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param&v=3",
                              headers: {"header" => "header"})
                        .and_return('get response')
      expect(@api.delete("any_url", {"param" => "param"}, {"header" => "header"})).to eq("get response")
    end


    # Not sure how to test, you'd need a revoked token.
    it "should raise UnauthorizedError if OAuth 1.0 returns unauthorized" do
      oauth = double("oauth")
      error_html = load_file(File.join('errors', 'auth_sub_401.html'))
      allow(oauth).to receive(:request).and_return(Net::HTTPUnauthorized.new("1.1", 401, error_html))
      api = GoogleContactsApi::Api.new(oauth)
      expect { api.get("any url",
                       {"param" => "param"},
                       {"header" => "header"}) }.to raise_error(GoogleContactsApi::UnauthorizedError)
    end

    it "should raise UnauthorizedError if OAuth 2.0 returns unauthorized" do
      oauth = double("oauth2")
      oauth2_response = Struct.new(:status)
      allow(oauth).to receive(:request).and_raise(MockOAuth2Error.new(oauth2_response.new(401)))
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

    before(:each) do
      @oauth = double("oauth")
      @user = GoogleContactsApi::User.new(@oauth)
      allow(@user.api).to receive(:get).and_return(Hashie::Mash.new({
                                                                      "body" => "some response", # could use example response here
                                                                      "code" => 200
                                                                    }))
      allow(GoogleContactsApi::GroupSet).to receive(:new).and_return("group set")
      allow(GoogleContactsApi::ContactSet).to receive(:new).and_return("contact set")
    end

    # Should hit the right URLs and return the right stuff
    describe ".groups" do
      it "should be able to get groups including system groups" do
        expect(user).to receive(:get_groups).and_return("group set")
        expect(user.groups).to eq("group set")
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
      it "should reload the contacts" do
        expect(user).to receive(:get_contacts).and_return("contact set").twice
        user.contacts
        contacts = user.contacts!
        expect(contacts).to eq("contact set")
      end
    end
    it 'gets contacts via query' do
      expect(@user.api).to receive(:get).with('contacts/default/full', 'q' => 'query', 'max-results' => 100000)
      expect(@user.query_contacts('query')).to eq("contact set")
    end
    it 'gets contacts via contacts_updated_min' do
      expect(@user.api).to receive(:get).with('contacts/default/full',
                                              'updated-min' => '2014-08-31T00:02:02.000Z', 'max-results' => 100000)
      expect(@user.contacts_updated_min(Time.new(2014, 8, 31, 2, 2, 2, '+02:00'))).to eq("contact set")
    end
    it 'gets a contact from an id url' do
      json = <<-EOS
        {
          "entry": [
            {
              "gd$name": {"gd$givenName": {"$t": "John"}},
              "id": {"$t": "http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c"}
            }
          ]
        }
      EOS
      expect(@user.api).to receive(:get).with('contacts/test.user%40example.com/full/6b70f8bb0372c')
                           .and_return(double(body: json, status: 200))
      contact = @user.get_contact('http://www.google.com/m8/feeds/contacts/test.user%40example.com/full/6b70f8bb0372c')
      expect(contact.given_name).to eq('John')
    end
    it 'allows you to delete a contact with a given id url and etag' do
      expected_url = 'https://www.google.com/m8/feeds/contacts/test.user%40gmail.com/full/6b70f8bb0372c?alt=json&v=3'
      expect(@oauth).to receive(:request).with(:delete, expected_url,  headers: { 'If-Match' => 'etag' })

      @user.delete_contact('http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/full/6b70f8bb0372c', 'etag')
    end
  end

  describe 'contact creation' do
    before do
      @oauth = double("oauth")
      @user = GoogleContactsApi::User.new(@oauth)
      @api = @user.api
      @contact_attrs =  {
        name_prefix: 'Mr',
        given_name: 'John',
        additional_name: 'Henry',
        family_name: 'Doe',
        name_suffix: 'III',
        content: 'this is content',
        emails: [
          { address: 'john@example.com', primary: true, rel: 'home' },
          { address: 'johnwork@example.com', primary: false, rel: 'work' },
        ],
        phone_numbers: [
          { number: '(123)-111-1111', primary: false, rel: 'other'},
          { number: '(456)-111-1111', primary: true, rel: 'mobile'}
        ],
        addresses: [
          { rel: 'work', primary: false, street: '123 Lane', city: 'Somewhere', region: 'IL',
            postcode: '12345', country: 'United States of America'},
          { rel: 'home', primary: true, street: '456 Road', city: 'Anywhere', region: 'IN',
            postcode: '67890', country: 'United States of America'},
        ],
        websites: [
          { rel: 'blog', primary: true, href: 'blog.example.com' },
          { rel: 'home-page', href: 'www.example.com' }
        ],
        organizations: [
          { org_name: 'Example, Inc', org_title: 'Manager', rel: 'other', primary: true }
        ],
        group_memberships: [],
        deleted_group_memberships: []
      }
      @contact_fields_xml = <<-EOS
        <gd:name>
          <gd:namePrefix>Mr</gd:namePrefix>
          <gd:givenName>John</gd:givenName>
          <gd:additionalName>Henry</gd:additionalName>
          <gd:familyName>Doe</gd:familyName>
          <gd:nameSuffix>III</gd:nameSuffix>
        </gd:name>
        <atom:content>this is content</atom:content>
        <gd:email rel="http://schemas.google.com/g/2005#home" primary="true" address="john@example.com"/>
        <gd:email rel="http://schemas.google.com/g/2005#work" address="johnwork@example.com"/>
        <gd:phoneNumber rel="http://schemas.google.com/g/2005#other">(123)-111-1111</gd:phoneNumber>
        <gd:phoneNumber rel="http://schemas.google.com/g/2005#mobile" primary="true">(456)-111-1111</gd:phoneNumber>
        <gd:structuredPostalAddress rel="http://schemas.google.com/g/2005#work">
          <gd:city>Somewhere</gd:city>
          <gd:street>123 Lane</gd:street>
          <gd:region>IL</gd:region>
          <gd:postcode>12345</gd:postcode>
          <gd:country>United States of America</gd:country>
        </gd:structuredPostalAddress>
        <gd:structuredPostalAddress rel="http://schemas.google.com/g/2005#home" primary="true">
          <gd:city>Anywhere</gd:city>
          <gd:street>456 Road</gd:street>
          <gd:region>IN</gd:region>
          <gd:postcode>67890</gd:postcode>
          <gd:country>United States of America</gd:country>
        </gd:structuredPostalAddress>
        <gd:organization rel="http://schemas.google.com/g/2005#other" primary="true">
          <gd:orgName>Example, Inc</gd:orgName>
          <gd:orgTitle>Manager</gd:orgTitle>
        </gd:organization>
        <gContact:website href="blog.example.com" rel="blog" primary="true"/>
        <gContact:website href="www.example.com" rel="home-page"/>
      EOS

      @contact_xml = <<-EOS
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005" xmlns:gContact="http://schemas.google.com/contact/2008">
          <atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
          #{@contact_fields_xml}
        </atom:entry>
      EOS

      @batch_create_xml = <<-EOS
      <atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005" xmlns:gContact="http://schemas.google.com/contact/2008">
          <atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
          <batch:id>batch id insert</batch:id>
          <batch:operation type="insert"/>
          #{@contact_fields_xml}
        </atom:entry>
      EOS

      @contact_json = <<-EOS
        {
          "entry": [
            {
              "gd$name": {"gd$givenName": {"$t": "John"}},
              "id": {"$t": "http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c"}
            }
          ]
        }
      EOS
    end

    it 'works without emails, phone numbers, addresses and websites specified and handles special characters and \v' do
      attrs =  { given_name: '<Jo&hn>', family_name: "Vertical Tab Replaced With Newline:\v" }
      xml = <<-EOS
        <atom:entry xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005" xmlns:gContact="http://schemas.google.com/contact/2008">
          <atom:category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
          <gd:name>
            <gd:givenName>&lt;Jo&amp;hn&gt;</gd:givenName>
            <gd:familyName>Vertical Tab Replaced With Newline:\n</gd:familyName>
          </gd:name>
        </atom:entry>
      EOS
      expect(Hash.from_xml(GoogleContactsApi::Contact.xml_for_create(attrs))).to eq(Hash.from_xml(xml))
    end

    it 'allows first a new then an update_or_create to create a new contact' do
      contact = GoogleContactsApi::Contact.new(nil, nil, @api)
      contact.prep_changes(@contact_attrs)

      expect(GoogleContactsApi::Contact).to receive(:xml_for_create).with(@contact_attrs).and_return(@contact_xml)

      expect(@oauth).to receive(:request)
                        .with(:post, 'https://www.google.com/m8/feeds/contacts/default/full?alt=json&v=3',
                              body: @contact_xml, headers: { 'Content-Type' => 'application/atom+xml' })
                        .and_return(double(body: @contact_json, status: 200))

      contact.create_or_update

      expect(contact.given_name).to eq('John')
      expect(contact.id).to eq('http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c')
    end

    it 'has batch_create_xml' do
      contact = GoogleContactsApi::Contact.new(nil, nil, @api)
      contact.prep_changes(@contact_attrs)
      expect(contact.prepped_changes).to eq(@contact_attrs)
      expect(contact.batch_create_xml('batch id insert')).to be_equivalent_to(@batch_create_xml)
    end
  end

  describe 'xml_util parse_as_if_alt_json' do
    let(:util) { GoogleContactsApi::XMLUtil }

    it 'parses simple feed' do
      xml = read_spec_file('google_sample_xml.xml')
      expected_parsed_json = JSON.parse(read_spec_file('google_sample_alt_json.json'))
      parsed = util.parse_as_if_alt_json(xml)
      expect(parsed).to eq(expected_parsed_json)
    end
  end

  describe 'send_batch_create_or_update' do
    before do
      @user = GoogleContactsApi::User.new(double("oauth"))
      @api = @user.api
    end

    it 'batches creation and update of contacts' do
      contact1 = GoogleContactsApi::Contact.new
      contact2 = GoogleContactsApi::Contact.new
      contact3 = GoogleContactsApi::Contact.new

      contacts = [contact1, contact2, contact3]
      expect(@user).to receive(:batch_xml).with(contacts).and_return('batch xml')

      expect(@api).to receive(:request).with(:post, 'contacts/default/full/batch', { 'alt' => '' }, 'batch xml',
                                             {'Content-Type' => 'application/atom+xml'})
                      .and_return(double(body: read_spec_file('batch_response.xml'), status: 200))

      expect(@user.last_batch_xml).to be_nil
      responses = @user.send_batch_create_or_update(contacts)
      expect(@user.last_batch_xml).to eq('batch xml')
      expect(responses).to eq([
                                {code: 201, reason: 'Created'}, {code: 200, reason: 'Success'}, {code: 500, reason: 'Internal Server Error'}
                              ])

      expect(contact1.given_name).to eq('John')
      expect(contact1.family_name).to eq('Doe')
      expect(contact1.emails_full).to eq([{:rel=>"work", :primary=>true, :address=>"john@example.com"}])

      expect(contact2.given_name).to eq('Jane')
      expect(contact2.family_name).to eq('Doe')
    end
  end

  describe 'send_batch_with_retries' do
    before do
      @user = GoogleContactsApi::User.new(double("oauth"))
    end

    it 'retries on a 500 error for the whole batch' do
      times_called = 0
      expect(@user).to receive(:send_batch_create_or_update).with('contacts').at_least(:twice) do
        times_called += 1
        raise GoogleContactsApi::Contacts::InternalServerError if times_called == 1
        'statuses'
      end

      expect(@user).to receive(:sleep).with(GoogleContactsApi::Contacts::RETRY_BATCH_DELAY_AFTER_ERROR)
      expect(@user.send_batch_with_retries('contacts')).to eq('statuses')
    end

    it 'retries on a 500 error for the whole batch' do
      expect(@user).to receive(:send_batch_create_or_update).with('contacts').at_least(:once)
                       .and_raise(GoogleContactsApi::Contacts::InternalServerError)
      expect(@user).to receive(:sleep).with(GoogleContactsApi::Contacts::RETRY_BATCH_DELAY_AFTER_ERROR)
      expect { @user.send_batch_with_retries('contacts') }.to raise_error
    end
  end

  describe 'batch create or update' do
    before do
      @user = GoogleContactsApi::User.new(double("oauth"))
    end

    it 'calls batch create with each then returns its status' do
      contacts = *(0..(GoogleContactsApi::Contacts::BATCH_SIZE + 1))
      expect(@user).to receive(:send_batch_with_retries) { |contacts| contacts }

      contacts.each_with_index do |contact, index|
        @user.batch_create_or_update(contact) do |status|
          expect(contact).to eq(status)

          next if index < contacts.size - 1
          expect(status).to eq(GoogleContactsApi::Contacts::BATCH_SIZE - 1)
        end
      end
    end

    it 'sends an incomplete batch when requested' do
      contacts = *(0..(GoogleContactsApi::Contacts::BATCH_SIZE - 2))
      expect(@user).to receive(:send_batch_with_retries) { |contacts| contacts }

      num_responses = 0
      contacts.each do |contact|
        @user.batch_create_or_update(contact) do |status|
          expect(contact).to eq(status)
          num_responses += 1
        end
      end

      expect(num_responses).to eq(0)
      @user.send_batched_requests
      expect(num_responses).to eq(contacts.size)
    end

    it 'does not call the api if you request batch save if no contacts are batched' do
      expect(@user).to receive(:send_batch_with_retries).exactly(0).times
      @user.send_batched_requests
    end

    it 'does not call the api if you request batch save if already emplied batch' do
      @user.batch_create_or_update('contact') { |status|  }
      expect(@user).to receive(:send_batch_with_retries).exactly(1).times.and_return(['status'])
      @user.send_batched_requests

      # Don't call the API after the batch has been completed
      @user.send_batched_requests
    end

    it 'clears a batch if an exception occurs' do
      contacts = *(0..(GoogleContactsApi::Contacts::BATCH_SIZE - 2))
      expect(@user).to receive(:send_batch_with_retries) { |contacts| contacts }

      num_responses = 0
      contacts.each do |contact|
        @user.batch_create_or_update(contact) do |status|
          num_responses += 1
          raise if num_responses == GoogleContactsApi::Contacts::BATCH_SIZE - 1
        end
      end

      expect(num_responses).to eq(0)
      expect { @user.send_batched_requests }.to raise_error
      expect(num_responses).to eq(GoogleContactsApi::Contacts::BATCH_SIZE - 1)

      expect(@user.batched_contacts).to be_empty
      expect(@user.batched_status_handlers).to be_empty
    end
  end

  describe 'group creation' do
    before do
      @oauth = double("oauth")
      @user = GoogleContactsApi::User.new(@oauth)
      @api = @user.api
      @group_attrs =  { title: 'test' }
      @group_xml = <<-EOS
          <atom:entry xmlns:gd="http://schemas.google.com/g/2005" xmlns:atom="http://www.w3.org/2005/Atom">
            <atom:category scheme="http://schemas.google.com/g/2005#kind"
              term="http://schemas.google.com/contact/2008#group"/>
            <atom:title type="text">test</atom:title>
          </atom:entry>
      EOS

      @group_json = <<-EOS
          {
            "entry": {
                "title": {"$t": "test"},
                "id": {"$t": "http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/7389"}
              }
          }
      EOS
    end

    it 'creates formats xml correctly from attributes' do
      expect(Hash.from_xml(GoogleContactsApi::Group.xml_for_create(@group_attrs))).to eq(Hash.from_xml(@group_xml))
    end

    it 'sends a request with the group xml and returns created Group instance' do
      expect(GoogleContactsApi::Group).to receive(:xml_for_create).with(@group_attrs).and_return(@group_xml)

      expect(@oauth).to receive(:request)
                        .with(:post, 'https://www.google.com/m8/feeds/groups/default/full?alt=json&v=3',
                              body: @group_xml, headers: { 'Content-Type' => 'application/atom+xml' })
                        .and_return(double(body: @group_json, status: 200))

      group = GoogleContactsApi::Group.create(@group_attrs, @api)

      expect(group.title).to eq('test')
      expect(group.id).to eq('http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/7389')
    end
  end

  describe 'updating a contact' do
    before do
      @oauth = double("oauth")
      @user = GoogleContactsApi::User.new(@oauth)
      parsed_json = {
        'gd$name' => {'gd$givenName' => {'$t' => 'John'}},
        'id' => {'$t' => 'http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c'},
        'gd$etag' => '"SXk6cDdXKit7I2A9Wh9VFUgORgE."'
      }

      @contact = GoogleContactsApi::Contact.new(parsed_json, nil, @user.api)

      @update_attrs = { family_name: 'Doe' }

      @augmented_update_attrs = {
        name_prefix: nil, given_name: 'John', additional_name: nil, family_name: 'Doe', name_suffix: nil,
        content: nil, emails: [], phone_numbers: [], addresses: [], organizations: [], websites: [],
        group_memberships: [], deleted_group_memberships: [],
        updated: '2014-09-01T16:25:34.010Z', etag: '"SXk6cDdXKit7I2A9Wh9VFUgORgE."',
        id: 'http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c'
      }

      @update_xml = @contact_xml = <<-EOS
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005"
               gd:etag="&quot;SXk6cDdXKit7I2A9Wh9VFUgORgE.&quot;">
          <id>http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c</id>
          <updated>2014-09-01T16:25:34.010Z</updated>
          <category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
          <gd:name>
            <gd:givenName>John</gd:givenName>
            <gd:familyName>Doe</gd:familyName>
          </gd:name>
        </entry>
      EOS

      @batch_update_xml =<<-EOS
        <entry xmlns="http://www.w3.org/2005/Atom" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:gd="http://schemas.google.com/g/2005"
               gd:etag="&quot;SXk6cDdXKit7I2A9Wh9VFUgORgE.&quot;">
          <id>http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c</id>
          <updated>2014-09-01T16:25:34.010Z</updated>
          <category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/contact/2008#contact"/>
          <batch:id>batch id update</batch:id>
          <batch:operation type="update"/>
          <gd:name>
            <gd:givenName>John</gd:givenName>
            <gd:familyName>Doe</gd:familyName>
          </gd:name>
        </entry>
      EOS

      @contact_json = <<-EOS
        {
          "entry": {
            "gd$name": {
              "gd$givenName": {"$t": "John"},
              "gd$familyName": {"$t": "Doe"}
            },
            "id": {"$t": "http://www.google.com/m8/feeds/contacts/test.user%40gmail.com/base/6b70f8bb0372c"}
          }
        }
      EOS
    end

    it 'formats xml correctly from attributes' do
      expect(@contact.xml_for_update(@augmented_update_attrs)).to be_equivalent_to(@update_xml)
    end

    it 'has batch_update_xml' do
      expect(GoogleContactsApi::Api).to receive(:format_time_for_xml).with(anything).and_return('2014-09-01T16:25:34.010Z')
      @contact.prep_changes(@update_attrs)
      expect(@contact.batch_update_xml('batch id update')).to be_equivalent_to(@batch_update_xml)
    end

    it 'does not send request if there are no changes' do
      expect(@oauth).to receive(:request).exactly(0).times
      @contact.send_update
    end

    it 'shows all attributes with changes via attrs_with_changes' do
      @contact.prep_changes(@update_attrs)
      expect(@contact.prepped_changes).to eq(@update_attrs)
      expect(@contact.attrs_with_changes).to eq(name_prefix: nil, given_name: 'John', additional_name: nil,
                                                family_name: 'Doe', name_suffix: nil, content: nil, emails: [], phone_numbers: [],
                                                addresses: [], organizations: [], websites: [], group_memberships: [],
                                                deleted_group_memberships: [],)
    end

    def mocks_for_contact_update
      expect(@contact).to receive(:xml_for_update).with(@augmented_update_attrs).and_return(@update_xml)

      expect(GoogleContactsApi::Api).to receive(:format_time_for_xml).with(anything).and_return('2014-09-01T16:25:34.010Z')

      expect(@oauth).to receive(:request)
                        .with(:put, 'https://www.google.com/m8/feeds/contacts/test.user%40gmail.com/full/6b70f8bb0372c?alt=json&v=3',
                              body: @contact_xml, headers: { 'If-Match' => '"SXk6cDdXKit7I2A9Wh9VFUgORgE."',
                                                             'Content-Type' => 'application/atom+xml' })
                        .and_return(double(body: @contact_json, status: 200))
    end

    it 'sends an api update request' do
      mocks_for_contact_update

      @contact.send_update(@update_attrs)
      expect(@contact.given_name).to eq('John')
      expect(@contact.family_name).to eq('Doe')
    end

    it 'supports prep update and send update' do
      mocks_for_contact_update

      @contact.prep_changes(@update_attrs)
      expect(@contact.prepped_changes).to eq(@update_attrs)
      @contact.send_update
      expect(@contact.given_name).to eq('John')
      expect(@contact.family_name).to eq('Doe')
    end

    it 'supports prep update and create_or_update' do
      mocks_for_contact_update

      @contact.prep_changes(@update_attrs)
      expect(@contact.prepped_changes).to eq(@update_attrs)
      @contact.create_or_update
      expect(@contact.given_name).to eq('John')
      expect(@contact.family_name).to eq('Doe')
    end
  end

  describe 'prep add to group' do
    before do
      user = GoogleContactsApi::User.new(double("oauth"))
      @contact = GoogleContactsApi::Contact.new(nil, nil, user.api)
      @contact['gContact$groupMembershipInfo'] = [
        { 'deleted' => 'false', 'href' => 'a' },
        { 'deleted' => 'true', 'href' => 'b' }
      ]
    end

    it 'supports prep add to group for a group it already has' do
      @contact.prep_add_to_group(double(id: 'a'))
      expect(@contact.prepped_changes).to eq({ group_memberships: ['a'], deleted_group_memberships: ['b']})
    end

    it 'supports prep add to group for a group that was deleted' do
      @contact.prep_add_to_group(double(id: 'b'))
      expect(@contact.prepped_changes).to eq({ group_memberships: ['a', 'b'], deleted_group_memberships: []})
    end

    it 'supports prep add to group for a group that it did not have before' do
      @contact.prep_add_to_group(double(id: 'c'))
      expect(@contact.prepped_changes).to eq({ group_memberships: ['a', 'c'], deleted_group_memberships: ['b']})
    end

    it 'supports prep add for multiple groups' do
      @contact.prep_add_to_group(double(id: 'c'))
      @contact.prep_add_to_group(double(id: 'd'))
      expect(@contact.prepped_changes).to eq({ group_memberships: ['a', 'c', 'd'], deleted_group_memberships: ['b']})
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
    # no testing, it's just an implementation detail to inherit
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
    it "should feat a photo with metadata" do
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

      it 'supports the deleted? method' do
        expect(GoogleContactsApi::Contact.new('gd$deleted' => {}).deleted?).to be_truthy
        expect(@contact_v3.deleted?).to be_falsey
      end

      it 'should catch nil values for nested fields' do
        expect(@empty.nested_t_field_or_nil('gd$name', 'gd$givenName')).to be_nil
        expect(@partly_empty.nested_t_field_or_nil('gd$name', 'gd$givenName')).to be_nil
        expect(@contact_v3.nested_t_field_or_nil('gd$name', 'gd$givenName')).to eq('John')
      end

      it 'has given_name' do
        expect(@contact_v3).to receive(:nested_t_field_or_nil).with('gd$name', 'gd$givenName').and_return('val')
        expect(@contact_v3.given_name).to eq('val')
      end

      it 'has family_name' do
        expect(@contact_v3).to receive(:nested_t_field_or_nil).with('gd$name', 'gd$familyName').and_return('val')
        expect(@contact_v3.family_name).to eq('val')
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
        expect(@contact_v3.phone_numbers_full).to eq([ { primary: true, number: '(123) 334-5158', rel: 'mobile' } ])
      end
      it 'has full emails' do
        expect(@empty.emails_full).to eq([])
        expect(@contact_v3.emails_full).to eq([ { primary: true, address: 'johnsmith@example.com', rel: 'other' } ])
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

      it 'has formatted attributes' do
        formatted_attrs = {
          name_prefix: nil, given_name: 'John', additional_name: nil, family_name: 'Doe', name_suffix: nil,
          content: nil, emails: [{primary: true, rel: 'other', address: 'johnsmith@example.com'}],
          phone_numbers: [{primary: true, rel: 'mobile', number: '(123) 334-5158'}],
          addresses: [{primary: false, rel: 'work', country: 'United States of America',
                       city: 'Somwhere', street: '2345 Long Dr. #232', region: 'IL', postcode: '12345'},
                      {primary: true, rel: 'home', country: 'United States of America',
                       city: 'Anywhere', street: '123 Far Ln.', region: nil, postcode: nil}],
          organizations: [{primary: false, rel: 'other', org_title: 'Worker Person', org_name: 'Example, Inc'}],
          websites: [],
          group_memberships: ['http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/111'],
          deleted_group_memberships: ['http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/222']
        }
        expect(@contact_v3.formatted_attrs).to eq(formatted_attrs)
      end

      describe 'format_address country' do
        before do
          @address = {
            'gd$country' => { '$t' => 'United States of America' },
            'gd$city' => { '$t' => 'Anywhere' },
            'gd$street' => { '$t' => '123 Big Rd' },
            'gd$region' => { '$t' => 'MO' },
            'gd$postcode' => { '$t' => '56789' }
          }
        end

        it 'formats a simple string country correctly' do
          expect(@contact_v3.format_address(@address)[:country]).to eq('United States of America')
        end

        it 'selects country text value when both code and text are present' do
          @address['gd$country'] = { 'code' => 'US', '$t' => 'United States of America' }
          expect(@contact_v3.format_address(@address)[:country]).to eq('United States of America')
        end

        it 'selects the country code if the country text is blank' do
          @address['gd$country'] = { 'code' => 'US', '$t' => '' }
          expect(@contact_v3.format_address(@address)[:country]).to eq('US')
        end

        it 'selects the country code if the country text is missing' do
          @address['gd$country'] = { 'code' => 'US' }
          expect(@contact_v3.format_address(@address)[:country]).to eq('US')
        end

        it 'returns nil if both are blank' do
          @address['gd$country'] = { }
          expect(@contact_v3.format_address(@address)[:country]).to be_nil
        end

        it 'returns nil if gd$country is missing' do
          @address.delete('gd$country')
          expect(@contact_v3.format_address(@address)[:country]).to be_nil
        end
      end
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
