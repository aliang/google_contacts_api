describe GoogleContactsApi::GroupSet do
  before(:all) do
    @group_set_json = group_set_json
    @group_set = GoogleContactsApi::GroupSet.new(@group_set_json)
  end

  specify "the right starting index is set" do
    expect(@group_set.start_index).to eq(1)
  end

  specify "the right number of results per page is set" do
    expect(@group_set.items_per_page).to eq(25)
  end

  specify "the right number of total results is set" do
    expect(@group_set.total_results).to eq(5)
  end

  specify "results are parsed into Groups" do
    expect(@group_set.to_a.first).to be_instance_of(GoogleContactsApi::Group)
  end
end
