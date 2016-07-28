describe GoogleContactsApi::User do
  let(:oauth) { double ("oauth") }
  let(:user) { GoogleContactsApi::User.new(@oauth) }

  describe "#groups" do
    it "calls 'get_groups' from GoogleContactsApi::Groups" do
      expect(user).to receive(:get_groups)
      user.groups
    end

    it "passess params to 'get_groups'" do
      expect(user).to receive(:get_groups).with(test: :param)
      user.groups(test: :param)
    end
  end

  describe "#groups!" do
    it "calls 'get_groups' from GoogleContactsApi::Groups" do
      expect(user).to receive(:get_groups)
      user.groups
    end

    it "passess params to 'get_groups'" do
      expect(user).to receive(:get_groups).with(test: :param)
      user.groups(test: :param)
    end

    it "resets groups" do
      expect(user).to receive(:get_groups).and_return("group set").twice
      user.groups
      groups = user.groups!
      expect(groups).to eq("group set")
    end
  end

  describe "#contacts" do
    it "calls 'get_contacts' from GoogleContactsApi::Contacts" do
      expect(user).to receive(:get_contacts)
      user.contacts
    end

    it "passess params to 'get_contacts'" do
      expect(user).to receive(:get_contacts).with(test: :param)
      user.contacts(test: :param)
    end
  end

  describe "#contacts!" do
    it "calls 'get_contacts' from GoogleContactsApi::Contacts" do
      expect(user).to receive(:get_contacts)
      user.contacts
    end

    it "passess params to 'get_contacts'" do
      expect(user).to receive(:get_contacts).with(test: :param)
      user.contacts(test: :param)
    end

    it "resets contacts" do
      expect(user).to receive(:get_contacts).and_return("contact set").twice
      user.contacts
      contacts = user.contacts!
      expect(contacts).to eq("contact set")
    end
  end

  describe "#contact" do
    it "passess params to 'get_contacts'" do
      expect(user).to receive(:get_contact).with(test: :param)
      user.contact(test: :param)
    end
  end
end
