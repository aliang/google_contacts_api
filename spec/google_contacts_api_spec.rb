require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

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
    it "should raise UnauthorizedError if token or request is invalid" do
      oauth = double("oauth")
      error_html = <<-ERROR_HTML
        <HTML>
        <HEAD>
        <TITLE>Token invalid - Invalid AuthSub token.</TITLE>
        </HEAD>
        <BODY BGCOLOR="#FFFFFF" TEXT="#000000">
        <H1>Token invalid - Invalid AuthSub token.</H1>
        <H2>Error 401</H2>
        </BODY>
        </HTML>
      ERROR_HTML
      error_html.strip!
      oauth.stub(:get).and_return(Net::HTTPUnauthorized.new("1.1", 401, error_html))
      api = GoogleContactsApi::Api.new(oauth)
      lambda { api.get("any url",
        {"param" => "param"},
        {"header" => "header"}) }.should raise_error(GoogleContactsApi::UnauthorizedError)
    end
    
    describe "parsing response code" do
      it "should parse something that looks like an oauth gem response" do
        Response = Struct.new(:code)
        GoogleContactsApi::Api.parse_response_code(Response.new("401")).should == 401
      end
      
      it "should parse something that looks like an oauth2 gem response" do
        Response = Struct.new(:status)
        GoogleContactsApi::Api.parse_response_code(Response.new("401")).should == 401
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
    it "should be able to get groups" do
      @user.api.should_receive(:get).with("groups/default/full", anything, {"GData-Version" => "2"})
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
      @oauth = mock("oauth")
      @oauth.stub(:get).and_return(Hashie::Mash.new({
        "body" => "some response", # could use example response here
        "code" => 200
      }))
      # @api = GoogleContactsApi::Api.new(@oauth)
      @api = mock("api")
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
      @api = mock("api")
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
