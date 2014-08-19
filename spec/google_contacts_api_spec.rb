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
      @oauth.stub(:get).and_return("get response")
      @api = GoogleContactsApi::Api.new(@oauth)
    end

    it "should perform a get request using oauth returning json" do
      # expectation should come before execution
      @oauth.should_receive(:get).with(
        GoogleContactsApi::Api::BASE_URL + "any_url?alt=json&param=param", {"header" => "header"})
      @api.get("any_url",
        {"param" => "param"},
        {"header" => "header"}).should == ("get response")
    end
    # Not implemented yet
    pending "should perform a post request using oauth"
    pending "should perform a put request using oauth"
    pending "should perform a delete request using oauth"
    # Not sure how to test, you'd need a revoked token.
    it "should raise UnauthorizedError if OAuth 1.0 returns unauthorized" do
      oauth = double("oauth")
      error_html = load_file(File.join('errors', 'auth_sub_401.html'))
      oauth.stub(:get).and_return(Net::HTTPUnauthorized.new("1.1", 401, error_html))
      api = GoogleContactsApi::Api.new(oauth)
      lambda { api.get("any url",
        {"param" => "param"},
        {"header" => "header"}) }.should raise_error(GoogleContactsApi::UnauthorizedError)
    end
    
    it "should raise UnauthorizedError if OAuth 2.0 returns unauthorized" do
      oauth = double("oauth2")
      oauth2_response = Struct.new(:status)
      oauth.stub(:get).and_raise(MockOAuth2Error.new(oauth2_response.new(401)))
      api = GoogleContactsApi::Api.new(oauth)
      lambda { api.get("any url",
        {"param" => "param"},
        {"header" => "header"}) }.should raise_error(GoogleContactsApi::UnauthorizedError)
    end
    
    describe "parsing response code" do
      before(:all) do
        @Oauth = Struct.new(:code)
        @Oauth2 = Struct.new(:status)
      end
      it "should parse something that looks like an oauth gem response" do
        GoogleContactsApi::Api.parse_response_code(@Oauth.new("401")).should == 401
      end

      it "should parse something that looks like an oauth2 gem response" do
        GoogleContactsApi::Api.parse_response_code(@Oauth2.new(401)).should == 401
      end
    end
  end

  describe "User" do
    before(:each) do
      @oauth = double("oauth")
      @user = GoogleContactsApi::User.new(@oauth)
      @user.api.stub(:get).and_return(Hashie::Mash.new({
        "body" => "some response", # could use example response here
        "code" => 200
      }))
      GoogleContactsApi::GroupSet.stub(:new).and_return("group set")
      GoogleContactsApi::ContactSet.stub(:new).and_return("contact set")
    end
    # Should hit the right URLs and return the right stuff
    it "should be able to get groups including system groups" do
      @user.api.should_receive(:get).with("groups/default/full", hash_including(:v => 2))
      @user.groups.should == "group set"
    end
    it "should be able to get contacts" do
      @user.api.should_receive(:get).with("contacts/default/full", anything)
      @user.contacts.should == "contact set"
    end
  end

  describe "ResultSet" do
    # no testing, it's just an implementation detail to use inheritance
  end

  describe "ContactSet" do
    describe "with entries" do
      before(:all) do
        @contact_set_json = contact_set_json
        @contact_set = GoogleContactsApi::ContactSet.new(@contact_set_json)
      end

      it "should return the right starting index" do
        @contact_set.start_index.should == 1
      end
      it "should return the right number of results per page" do
        @contact_set.items_per_page.should == 25
      end
      it "should return the right number of total results" do
        @contact_set.total_results.should == 500
      end
      it "should tell me if there are more results" do
        # yeah this is an awkward assertion and matcher
        @contact_set.should be_has_more
        @contact_set.has_more?.should == true
      end
      it "should parse results into Contacts" do
        @contact_set.to_a.first.should be_instance_of(GoogleContactsApi::Contact)
      end
    end
    it "should parse nil results into an empty array" do
      @empty_contact_set_json = empty_contact_set_json
      @empty_contact_set = GoogleContactsApi::ContactSet.new(@empty_contact_set_json)
      @empty_contact_set.total_results.should == 0
      @empty_contact_set.instance_variable_get("@results").should == []
    end
  end

  describe "GroupSet" do
    before(:all) do
      @group_set_json = group_set_json
      @group_set = GoogleContactsApi::GroupSet.new(@group_set_json)
    end

    it "should return the right starting index" do
      @group_set.start_index.should == 1
    end
    it "should return the right number of results per page" do
      @group_set.items_per_page.should == 25
    end
    it "should return the right number of total results" do
      @group_set.total_results.should == 5
    end
    it "should tell me if there are more results" do
      # yeah this is an awkward assertion and matcher
      @group_set.should_not be_has_more
      @group_set.has_more?.should == false
    end
    it "should parse results into Groups" do
      @group_set.to_a.first.should be_instance_of(GoogleContactsApi::Group)
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
      @contact.title.should == "Contact 1"
    end
    it "should return the right id" do
      @contact.id.should == "http://www.google.com/m8/feeds/contacts/example%40gmail.com/base/0"
    end
    it "should return the right content" do
      # TODO: Nothing in source, oops
      @contact.content.should == nil
    end
    it "should return the right updated time" do
      # different representation slightly
      @contact.updated.to_s.should == "2011-07-07T21:02:42+00:00"
    end
    it "should return the right self link" do
      @contact.self_link.should == "https://www.google.com/m8/feeds/contacts/example%40gmail.com/full/0"
    end
    it "should return the right photo link" do
      @contact.photo_link.should == "https://www.google.com/m8/feeds/photos/media/example%40gmail.com/0"
    end
    it "should return the right edit link" do
      @contact.edit_link.should == "https://www.google.com/m8/feeds/contacts/example%40gmail.com/full/0"
    end
    it "should return the right edit photo link" do
      # TODO: there isn't one in this contact, hahah
      @contact.edit_photo_link.should == nil
    end
    it "should try to fetch a photo" do
      @oauth = double("oauth")
      @oauth.stub(:get).and_return(Hashie::Mash.new({
        "body" => "some response", # could use example response here
        "code" => 200
      }))
      # @api = GoogleContactsApi::Api.new(@oauth)
      @api = double("api")
      @api.stub(:oauth).and_return(@oauth)
      @contact = GoogleContactsApi::Contact.new(@contact_json_hash, nil, @api)
      @oauth.should_receive("get").with(@contact.photo_link)
      @contact.photo
    end
    # TODO: there isn't any phone number in here
    pending "should return all phone numbers"
    it "should return all e-mail addresses" do
      @contact.emails.should == ["contact1@example.com"]
    end
    it "should return the right primary e-mail address" do
      @contact.primary_email.should == "contact1@example.com"
    end
    it "should return an empty array if there are no e-mail addresses" do
      @contact = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
      @contact.emails.should == []
    end
    it "should return nil if there is no primary e-mail address" do
      @contact2 = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
      @contact2.primary_email.should be_nil
      @contact3 = GoogleContactsApi::Contact.new(contact_no_primary_email_json_hash)
      @contact3.primary_email.should be_nil
    end
    it "should return all instant messaging accounts" do
      @contact.ims.should == ["contact1@example.com"]
    end
    it "should return an empty array if there are no instant messaging accounts" do
      @contact = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
      @contact.ims.should == []
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
              'gd$country' => { '$t' => 'United States of America' },
              'gd$formattedAddress' => { '$t' => "123 Far Ln.\nAnywhere\nMO\n67891\nUnited States of America" },
              'gd$city' => { '$t' => 'Anywhere' },
              'gd$street' => { '$t' => '123 Far Ln.' },
              'gd$region' => { '$t' => 'MO' },
              'gd$postcode' => { '$t' => '67891' }
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
          ]
        )
      end

      it 'should catch nil values for nested fields' do
        @empty.nested_t_field_or_nil('gd$name', 'gd$givenName').should be_nil
        @partly_empty.nested_t_field_or_nil('gd$name', 'gd$givenName').should be_nil
        @contact_v3.nested_t_field_or_nil('gd$name', 'gd$givenName').should eq('John')
      end

      it 'has given_name' do
        @contact_v3.should_receive(:nested_t_field_or_nil).with('gd$name', 'gd$givenName').and_return('val')
        @contact_v3.given_name.should eq('val')
      end

      it 'has family_name' do
        @contact_v3.should_receive(:nested_t_field_or_nil).with('gd$name', 'gd$familyName').and_return('val')
        @contact_v3.family_name.should eq('val')
      end

      it 'has full_name' do
        @contact_v3.should_receive(:nested_t_field_or_nil).with('gd$name', 'gd$fullName').and_return('val')
        @contact_v3.full_name.should eq('val')
      end

      it 'has relations' do
        @empty.relations.should eq([])
        @partly_empty.relations.should eq([])
        @contact_v3.relations.should eq([ { '$t' => 'Jane', 'rel' => 'spouse' } ])
      end
      it 'has spouse' do
        @empty.spouse.should be_nil
        @partly_empty.spouse.should be_nil
        @contact_v3.spouse.should eq('Jane')
      end
      
      it 'has addresses' do
        @empty.addresses.should eq([])

        formatted_addresses = [
          {
              :rel => 'work',
              :country => 'United States of America',
              :formatted_address => "2345 Long Dr. #232\nSomwhere\nIL\n12345\nUnited States of America",
              :city => 'Somwhere',
              :street => '2345 Long Dr. #232',
              :region => 'IL',
              :postcode => '12345'
          },
          {
              :rel => 'home',
              :country => 'United States of America',
              :formatted_address => "123 Far Ln.\nAnywhere\nMO\n67891\nUnited States of America",
              :city => 'Anywhere',
              :street => '123 Far Ln.',
              :region => 'MO',
              :postcode => '67891'
          }
        ]
        @contact_v3.addresses.should eq(formatted_addresses)
      end

      it 'has full phone numbers' do
        @empty.phone_numbers_full.should eq([])
        @contact_v3.phone_numbers_full.should eq([ { :primary => true, :number => '(123) 334-5158', :rel => 'mobile' } ])
      end
      it 'has full emails' do
        @empty.emails_full.should eq([])
        @contact_v3.emails_full.should eq([ { :primary => true, :address => 'johnsmith@example.com', :rel => 'other' } ])
      end
    end
  end

  describe "Group" do
    before(:all) do
      @group_json_hash = group_json_hash
      @group = GoogleContactsApi::Group.new(group_json_hash)
    end
    # ok, these tests are kind of silly
    it "should return the right title" do
      @group.title.should == "System Group: My Contacts"
    end
    it "should return the right id" do
      @group.id.should == "http://www.google.com/m8/feeds/groups/example%40gmail.com/base/6"
    end
    it "should return the right content" do
      # TODO: Nothing in source, oops
      @group.content.should == "System Group: My Contacts"
    end
    it "should return the right updated time" do
      # different representation slightly
      @group.updated.to_s.should == "1970-01-01T00:00:00+00:00"
    end
    it "should tell me if it's a system group" do
      @group.should be_system_group
    end
    it "should get contacts from the group and cache them" do
      @api = double("api")
      @api.stub(:get).and_return(Hashie::Mash.new({
        "body" => "some response", # could use example response here
        "code" => 200
      }))
      GoogleContactsApi::ContactSet.stub(:new).and_return("contact set")
      @group = GoogleContactsApi::Group.new(@contact_json_hash, nil, @api)
      @api.should_receive("get").with(an_instance_of(String),
        hash_including({"group" => @group.id})).once
      @group.contacts
      @group.contacts
    end
  end
end
