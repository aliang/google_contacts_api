describe GoogleContactsApi::ContactSet do
  context "when entries are present" do
    before(:all) do
      @contact_set_json = contact_set_json
      @contact_set = GoogleContactsApi::ContactSet.new(@contact_set_json)
    end

    specify "the right starting index is set" do
      expect(@contact_set.start_index).to eq(1)
    end

    specify "the right number of results per page is set" do
      expect(@contact_set.items_per_page).to eq(25)
    end

    specify "the right number of total results is set" do
      expect(@contact_set.total_results).to eq(500)
    end

    specify "results are parsed into Contacts" do
      expect(@contact_set.to_a.first).to be_instance_of(GoogleContactsApi::Contact)
    end
  end

  context "when entries are not present" do
    before(:all) do
      @empty_contact_set_json = empty_contact_set_json
      @empty_contact_set = GoogleContactsApi::ContactSet.new(@empty_contact_set_json)
    end

    specify "totals_results is equal to 0" do
      expect(@empty_contact_set.total_results).to eq(0)
    end

    specify "@results variable is an empty array" do
      expect(@empty_contact_set.instance_variable_get("@results")).to eq([])
    end
  end
end
