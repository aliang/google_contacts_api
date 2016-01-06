describe GoogleContactsApi::Group do
  subject { GoogleContactsApi::Group.new(group_json_hash) }

  describe "#system_group?" do
    context "when group has system group" do
      it "returns true" do
        expect(subject).to be_system_group
      end
    end

    context "when group has no system group" do
      it "returns false" do
        @group = GoogleContactsApi::Group.new(group_not_system_json_hash)
        expect(@group).not_to be_system_group
      end
    end
  end

  describe "#system_group_id" do
    context "when system group is set" do
      it "returns system group id" do
        expect(subject.system_group_id).to eq('Contacts')
      end
    end

    context "when system group is not set" do
      it "returns nil" do
        @group = GoogleContactsApi::Group.new(group_not_system_json_hash)
        expect(@group.system_group_id).to be_nil
      end
    end
  end

  describe "#contacts" do
    before do
      @api = double("api")
      @group = GoogleContactsApi::Group.new(contact_json_hash, nil, @api)
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

  describe "#contacts!" do
    before do
      @api = double("api")
      @group = GoogleContactsApi::Group.new(contact_json_hash, nil, @api)
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

  describe "#links" do
    it "returns an array of hrefs" do
      expect(subject.links).to eq ["https://www.google.com/m8/feeds/groups/example%40gmail.com/full/6"]
    end
  end

  describe "#self_link" do
    it "returns href of the link with rel = 'self'" do
      expect(subject.self_link).to eq "https://www.google.com/m8/feeds/groups/example%40gmail.com/full/6"
    end
  end

  describe "#edit_link" do
    it "returns hre of the link with rel = 'edit'" do
      group = GoogleContactsApi::Group.new(group_not_system_json_hash)
      expect(group.edit_link).to eq "https://www.google.com/m8/feeds/groups/example%40gmail.com/full/270f"
    end
  end

  describe "#delete" do
    it "does an oauth delete request for the group" do
      oauth = double("oauth")
      user = GoogleContactsApi::User.new(oauth)
      api = user.api
      group = GoogleContactsApi::Group.new(group_not_system_json_hash)
      id_url = "https://www.google.com/m8/feeds/groups/example%40gmail.com/full/270f?alt=json&v=3"
      etag = "\"Q3c4fjVSLyp7ImA9WB9VEE4PRgQ.\""
      expect(oauth).to receive(:request)
        .with(:delete, id_url, headers: { "If-Match" => etag })
      group.delete(api)
    end
  end

  describe ".create" do
    before do
      @oauth = double("oauth")
      @user = GoogleContactsApi::User.new(@oauth)
      @api = @user.api
      @title =  'test'
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

    it 'formats creation xml correctly from attributes' do
      expect(Hash.from_xml(GoogleContactsApi::Group.xml_for_create(@title)))
        .to eq(Hash.from_xml(@group_xml))
    end

    it 'sends a request with the group xml and returns created Group instance' do
      expect(GoogleContactsApi::Group).to receive(:xml_for_create)
        .with(@title).and_return(@group_xml)

      expect(@oauth).to receive(:request)
        .with(:post, 'https://www.google.com/m8/feeds/groups/default/full?alt=json&v=3',
      body: @group_xml, headers: { 'Content-Type' => 'application/atom+xml' })
        .and_return(double(body: @group_json, status: 200))

      group = GoogleContactsApi::Group.create(@api, @title)

      expect(group.title).to eq('test')
      expect(group.id).to eq('http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/7389')
    end
  end
end
