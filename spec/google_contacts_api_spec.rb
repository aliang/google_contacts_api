require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "GoogleContactsApi" do
  describe "Api" do
    before(:each) do
      @oauth = double("oauth")
      @oauth.stub(:get).and_return("get response")
      @api = GoogleContactsApi::Api.new(@oauth)
    end

    it "should perform a get request using oauth" do
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
    end
    # Need an example result to parse
    pending "should return the right starting index"
    pending "should return the right number of results per page"
    pending "should return the right number of total results"
    pending "should tell me if there are more results"
    pending "should parse results into Contacts"
  end
  
  describe "GroupSet" do
    before(:all) do
      @group_set_json = group_set_json
    end
    pending "should return the right starting index"
    pending "should return the right number of results per page"
    pending "should return the right number of total results"
    pending "should tell me if there are more results"
    pending "should parse results into Groups"
  end
  
  describe "Result" do
    # no testing, it's just an implementation detail to inherit
  end
  
  describe "Contact" do
    before(:all) do
      @contact_json = contact_json
    end
    pending "should return the right title"
    pending "should return the right id"
    pending "should return the right primary e-mail address"
  end
  
  describe "Group" do
    before(:all) do
      @group_json = group_json
    end
    pending "should return the right title"
    pending "should return the right id"
  end
end
