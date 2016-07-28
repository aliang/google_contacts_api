class TestClass
  include GoogleContactsApi::Contacts

  def initialize(api)
    @api = api
  end
end

describe GoogleContactsApi::Contacts do
  let(:api) { double("api") }
  let(:test_class) { TestClass.new(api) }
  let(:server_response) do
    OpenStruct.new(
      code: 200,
      body: contact_set_json
    )
  end

  let(:contact_response) do
    OpenStruct.new(
      code: 200,
      body: contact_json
    )
  end

  describe "#get_contacts" do
    before do
      allow(api).to receive(:get).and_return(server_response)
    end

    it "calls 'get' on api" do
      expect(api).to receive(:get).with("contacts/default/full", kind_of(Hash)).and_return(server_response)
      test_class.get_contacts
    end

    it "returns contacts set" do
      expect(test_class.get_contacts).to be_an_kind_of GoogleContactsApi::ContactSet
    end
  end

  describe "#get_contact" do
    before do
      allow(api).to receive(:get).and_return(contact_response)
    end

    it "calls 'get' on api" do
      expect(api).to receive(:get).with("contacts/default/full/abcd", kind_of(Hash)).and_return(contact_response)
      test_class.get_contact(contact_id: 'abcd')
    end

    it "returns contact" do
      expect(test_class.get_contact).to be_an_kind_of GoogleContactsApi::Contact
    end
  end
end
