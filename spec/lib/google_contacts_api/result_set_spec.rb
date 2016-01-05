describe GoogleContactsApi::ResultSet do
  subject { GoogleContactsApi::ResultSet.new(contact_set_json) }

  describe "#each" do
    context "when block is provided" do
      it "yields to block for each result" do
        expect(subject.instance_variable_get(:@results)).to receive(:each)
        subject.each { |x| x }
      end
    end

    context "when block is not provided" do
      it "returns an enumerator" do
        expect(subject.each).to be_a_kind_of Enumerator
      end
    end
  end

  describe "#has_more?" do
    context "when there are more results" do
      it "returns true" do
        expect(subject.has_more?).to be true
      end
    end

    context "when there are no results anymore" do
      it "returns false" do
        total_results = subject.instance_variable_get(:@total_results)
        per_page = subject.instance_variable_get(:@items_per_page)
        subject.instance_variable_set(:@start_index, total_results - per_page + 2)
        expect(subject.has_more?).to be false
      end
    end
  end
end
