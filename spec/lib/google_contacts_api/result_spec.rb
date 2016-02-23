describe GoogleContactsApi::Result do
  subject do
    GoogleContactsApi::Result.new({
      "id" => {
        "$t" => "http://www.google.com/m8/feeds/contacts/example%40gmail.com/base/0"
      },
      "gd$etag" => "\"Rno6fDVSLit7I2A9XRNREEUORAH.\"",
      "updated" => {
        "$t" => "2011-07-07T21:02:42.360Z"
      },
      "title" => {
          "$t" => "Contact 1"
      },
      "content" => {
          "$t" => "Contact 1 Content"
      },
      "category" => [{
        "scheme" => "http =>//schemas.google.com/g/2005#kind",
        "term" => "http =>//schemas.google.com/contact/2008#contact"
      }],
      "gd$deleted" => true
    })
  end

  describe "#id" do
    it "returns id parsed from entry" do
      expect(subject.id).to eq "http://www.google.com/m8/feeds/contacts/example%40gmail.com/base/0"
    end
  end

  describe "#etag" do
    it "returns etag parsed from entry" do
      expect(subject.etag).to eq "\"Rno6fDVSLit7I2A9XRNREEUORAH.\""
    end
  end

  describe "#id_path" do
    it "returns item path relative to the base Google contacts URL" do
      expect(subject.id_path).to eq "contacts/example%40gmail.com/full/0"
    end
  end

  describe "#title" do
    it "returns title parsed from entry" do
      expect(subject.title).to eq "Contact 1"
    end
  end

  describe "#content" do
    it "returns content parsed from entry" do
      expect(subject.content).to eq "Contact 1 Content"
    end
  end

  describe "#updated" do
    it "returns updated parsed from entry" do
      expect(subject.updated).to be_a_kind_of DateTime
      expect(subject.updated.to_s).to eq "2011-07-07T21:02:42+00:00"
    end
  end

  describe "#categories" do
    it "returns category parsed from entry" do
      expect(subject.categories).to eq subject.category
    end
  end

  describe "#deleted?" do
    context "when 'gd$deleted' is presented in the entry" do
      it "returns true" do
        expect(subject.deleted?).to eq true
      end
    end

    context "when 'gd$deleted' is not presented in the entry" do
      it "returns false" do
        not_deleted_entry = GoogleContactsApi::Result.new("id" => "123")
        expect(not_deleted_entry.deleted?).to eq false
      end
    end
  end
end
