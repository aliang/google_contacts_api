class TestClass
  include GoogleContactsApi::Groups
  
  def initialize(api)
    @api = api
  end
end

describe GoogleContactsApi::Groups do
  let(:api) { double("api") }
  let(:test_class) { TestClass.new(api) }
  let(:server_response) do
    OpenStruct.new(
      code: 200,
      body: group_set_json
    )
  end

  describe "#get_groups" do
    before do
      allow(api).to receive(:get).and_return(server_response)
    end

    it "calls 'get' on api" do
      expect(api).to receive(:get).with("groups/default/full", kind_of(Hash)).and_return(server_response)
      test_class.get_groups
    end

    it "returns groups set" do
      expect(test_class.get_groups).to be_an_kind_of GoogleContactsApi::GroupSet
    end
  end

  describe "#create_group" do
    let(:expected_create_xml) do
      <<-EOS
        <atom:entry xmlns:gd="http://schemas.google.com/g/2005" xmlns:atom="http://www.w3.org/2005/Atom">
          <atom:category scheme="http://schemas.google.com/g/2005#kind"
            term="http://schemas.google.com/contact/2008#group"/>
          <atom:title type="text">test_title</atom:title>
        </atom:entry>
      EOS
    end
    let(:stubbed_create_response) do
      <<-EOS
        {
          "entry": {
              "title": {"$t": "test_title"},
              "id": {"$t": "http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/7389"}
            }
        }
      EOS
    end

    it "does an api post request with xml for creating the group" do
      expect(api).to receive(:post) do |url, body, params, headers|
        expect(url).to eq("groups/default/full")
        expect(params).to eq({})
        expect(body).to be_equivalent_to(expected_create_xml)
        expect(headers).to eq("Content-Type" => "application/atom+xml")
        double("response", body: stubbed_create_response)
      end
      group = test_class.create_group("test_title")
      expect(group.title).to eq("test_title")
      expect(group.id).to eq("http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/7389")
    end
  end

  describe "#delete_group" do
    it "does an api delete request for the group" do
      id_url = "groups/example%40gmail.com/full/270f"
      etag = "\"Q3c4fjVSLyp7ImA9WB9VEE4PRgQ.\""
      expect(api).to receive(:delete).with(id_url, {}, "If-Match" => etag)

      group = GoogleContactsApi::Group.new(group_not_system_json_hash)
      test_class.delete_group(group)
    end
  end
end
