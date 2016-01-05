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
end
