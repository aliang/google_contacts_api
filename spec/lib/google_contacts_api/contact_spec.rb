describe GoogleContactsApi::Contact do
  subject { GoogleContactsApi::Contact.new(contact_json_hash) }

  describe "#self_link" do
    it "returns correct self_link" do
      expect(subject.self_link).to eq("https://www.google.com/m8/feeds/contacts/example%40gmail.com/full/0")
    end
  end

  describe "#photo_link_entry" do
    it "returns correct photo_link_entry" do
      expect(subject.photo_link_entry).to eq({
        "rel" => "http://schemas.google.com/contacts/2008/rel#photo",
        "type" => "image/*",
        "href" => "https://www.google.com/m8/feeds/photos/media/example%40gmail.com/0",
        "gd$etag" => "\"dxt2DAEZfCp7ImA-AV4zRxBoPG4UK3owXBM.\""
      })
    end
  end

  describe "#photo_link" do
    it "returns correct photo_link" do
      expect(subject.photo_link).to eq("https://www.google.com/m8/feeds/photos/media/example%40gmail.com/0")
    end
  end

  describe "#edit_link" do
    it "returns correct edit_link" do
      expect(subject.edit_link).to eq("https://www.google.com/m8/feeds/contacts/example%40gmail.com/full/0")
    end
  end

  describe "#edit_photo_link" do
    it "returns correct edit_photo_link" do
      # TODO: there isn't one in this contact, hahah
      expect(subject.edit_photo_link).to eq(nil)
    end
  end

  describe "#photo" do
    it "fetches a photo" do
      @oauth = double("oauth")
      allow(@oauth).to receive(:get).and_return(Hashie::Mash.new({
        "body" => "some response", # could use example response here
        "code" => 200
      }))
      @api = double("api")
      allow(@api).to receive(:oauth).and_return(@oauth)
      @contact = GoogleContactsApi::Contact.new(contact_json_hash, nil, @api)

      expect(@oauth).to receive("get").with(@contact.photo_link)

      @contact.photo
    end
  end

  describe "#photo_with_metadata" do
    it "returns photo with metadata" do
      @oauth = double("oauth")
      allow(@oauth).to receive(:get).and_return(Hashie::Mash.new({
        "body" => "some response",
        "code" => 200,
        "headers" => { "content-type" => "image/jpeg" }
      }))
      @api = double("api")
      allow(@api).to receive(:oauth).and_return(@oauth)
      @contact = GoogleContactsApi::Contact.new(contact_json_hash, nil, @api)

      expect(@oauth).to receive("get").with(@contact.photo_link)
      expect(@contact.photo_with_metadata).to eq(
        data: 'some response',
        etag: 'dxt2DAEZfCp7ImA-AV4zRxBoPG4UK3owXBM.',
        content_type: 'image/jpeg'
      )
    end
  end

  describe "#emails" do
    context 'when emails are specified' do
      it "returns an array of emails" do
        expect(subject.emails).to eq(["contact1@example.com"])
      end
    end

    context 'when emails are not specified' do
      it "returns an empty array" do
        @contact = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
        expect(@contact.emails).to eq([])
      end
    end
  end

  describe "#primary_email" do
    context "when primary email is set" do
      it "returns correct primary email" do
        expect(subject.primary_email).to eq("contact1@example.com")
      end
    end

    context "when primary email is not set" do
      it "returns nil" do
        @contact2 = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
        expect(@contact2.primary_email).to be_nil
        @contact3 = GoogleContactsApi::Contact.new(contact_no_primary_email_json_hash)
        expect(@contact3.primary_email).to be_nil
      end
    end
  end

  describe "#ims" do
    context "when instant messaging accounts are specified" do
      it "returns instan messaging accounts" do
        expect(subject.ims).to eq(["contact1@example.com"])
      end
    end

    context "when instant messaging accounts are not specified" do
      it "returns an empty array" do
        @contact = GoogleContactsApi::Contact.new(contact_no_emails_json_hash)
        expect(@contact.ims).to eq([])
      end
    end
  end

  #
  describe 'Contacts API v3 fields' do
    before do
      @empty = GoogleContactsApi::Contact.new

      @partly_empty = GoogleContactsApi::Contact.new(
        'gd$name' => {},
        'gContact$relation' => []        
      )

      @contact_v3 = GoogleContactsApi::Contact.new(
        'gd$name' => {
          'gd$givenName' => { '$t' => 'John' },
          'gd$familyName' => { '$t' => 'Doe' },
          'gd$fullName' => { '$t' => 'John Doe' }
        },
        'gContact$birthday' => {
          'when' => '1988-05-12'
        },
        'gContact$relation' => [ { '$t' => 'Jane', 'rel' => 'spouse' } ],
        'gd$structuredPostalAddress' => [
          {
            'gd$country' => { '$t' => 'United States of America' },
            'gd$formattedAddress' => { '$t' => "2345 Long Dr. #232\nSomwhere\nIL\n12345\nUnited States of America" },
            'gd$city' => { '$t' => 'Somwhere' },
            'gd$street' => { '$t' => '2345 Long Dr. #232' },
            'gd$region' => { '$t' => 'IL' },
            'gd$postcode' => { '$t' => '12345' }
          },
          {
            'rel' => 'http://schemas.google.com/g/2005#home',
            'primary' => 'true',
            'gd$country' => { '$t' => 'United States of America' },
            'gd$formattedAddress' => { '$t' => "123 Far Ln.\nAnywhere\nMO\n67891\nUnited States of America" },
            'gd$city' => { '$t' => 'Anywhere' },
            'gd$street' => { '$t' => '123 Far Ln.' }
          }
        ],
        'gd$email' => [
          {
            'primary' => 'true',
            'rel' => 'http://schemas.google.com/g/2005#other',
            'address' => 'johnsmith@example.com'
          }
        ],
        'gd$phoneNumber' => [
          {
            'primary' => 'true',
            '$t' => '(123) 334-5158',
            'rel' => 'http://schemas.google.com/g/2005#mobile'
          }
        ],
        'gd$organization' => [
          {
            'gd$orgTitle' => { '$t' => 'Worker Person' },
            'gd$orgName' => { '$t' => 'Example, Inc' },
            'rel' => 'http://schemas.google.com/g/2005#other'
          }
        ],
        'gContact$groupMembershipInfo' => [
          {
            'deleted' => 'false',
            'href' => 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/111'
          },
          {
            'deleted' => 'true',
            'href' => 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/222'
          }
        ]
      )
    end

    describe '#nested_t_field_or_nil' do
      context "when nested fields are present" do
        it "returns correct value" do
          expect(@contact_v3.nested_t_field_or_nil('gd$name', 'gd$givenName')).to eq('John')
        end
      end

      context "when nested fields are not present" do
        it "returns nil" do
          expect(@empty.nested_t_field_or_nil('gd$name', 'gd$givenName')).to be_nil
          expect(@partly_empty.nested_t_field_or_nil('gd$name', 'gd$givenName')).to be_nil
        end
      end
    end

    describe "#given_name" do
      it "returns given name" do
        expect(@contact_v3.given_name).to eq('John')
      end
    end

    describe "#family_name" do
      it "returns family name" do
        expect(@contact_v3.family_name).to eq('Doe')
      end
    end

    describe "#full_name" do
      it "returns full name" do
        expect(@contact_v3).to receive(:nested_t_field_or_nil).with('gd$name', 'gd$fullName').and_return('val')
        expect(@contact_v3.full_name).to eq('val')
      end
    end

    describe "#phone_numbers" do
      it "returns an array of phone numbers" do
        expect(@contact_v3.phone_numbers).to eq ["(123) 334-5158"]
      end
    end

    describe "#relations" do
      context "when relations are set" do
        it "returns relations" do
          expect(@contact_v3.relations).to eq([ { '$t' => 'Jane', 'rel' => 'spouse' } ])
        end
      end

      context "when relations are not set" do
        it "returns an empty array" do
          expect(@empty.relations).to eq([])
          expect(@partly_empty.relations).to eq([])
        end
      end
    end

    describe "#spouse" do
      context "when spouse is set" do
        it "returns spouse" do
          expect(@contact_v3.spouse).to eq('Jane')
        end
      end

      context "when spouse is not set" do
        it "returns nil" do
          expect(@empty.spouse).to be_nil
          expect(@partly_empty.spouse).to be_nil
        end
      end
    end

    describe "#birthday" do
      context "when full birthday is set" do
        it "returns full birthday" do
          expect(@contact_v3.birthday).to eq({ year: 1988, month: 5, day: 12 })
        end
      end

      context "when year is not specified" do
        it "returns partial birthday" do
          contact_birthday_no_year = GoogleContactsApi::Contact.new('gContact$birthday' => { 'when' => '--05-12' })
          expect(contact_birthday_no_year.birthday).to eq({ year: nil, month: 5, day: 12 })
        end
      end

      context "when birthday is not set" do
        it "returns nil" do
          expect(@empty.birthday).to be_nil
        end
      end
    end

    describe "#addresses" do
      context "when addresses are specified" do
        it "returns addresses" do
          formatted_addresses = [
            { rel: 'work', primary: false, country: 'United States of America', city: 'Somwhere', street: '2345 Long Dr. #232',
              region: 'IL', postcode: '12345' },
            { rel: 'home', primary: true, country: 'United States of America', city: 'Anywhere', street: '123 Far Ln.',
              region: nil, postcode: nil }
          ]
          expect(@contact_v3.addresses).to eq(formatted_addresses)
        end
      end

      context "when addresses are not specified" do
        it "returns an empty arary" do
          expect(@empty.addresses).to eq([])
        end
      end
    end

    describe "#phone_numbers_full" do
      context "when phone numbers are specified" do
        it "returns full phone numbers" do
          expect(@contact_v3.phone_numbers_full).to eq([ { :primary => true, :number => '(123) 334-5158', :rel => 'mobile' } ])
        end
      end

      context "when phone numbers are not specified" do
        it "returns an empty array" do
          expect(@empty.phone_numbers_full).to eq([])
        end
      end
    end

    describe "#gourp_membership_info" do
      context "when gourp membership info is specified" do
        it "returns gourp membership info" do
          group_membership_info = [
            { deleted: false, href: 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/111' },
            { deleted: true, href: 'http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/222' }
          ]
          expect(@contact_v3.group_membership_info).to eq(group_membership_info)
        end
      end

      context "when gourp membership info is not specified" do
        it "returns an empty array" do
          expect(@empty.group_membership_info).to eq([])
        end
      end
    end

    describe "#organizations" do
      context "when organizations are specified" do
        it "returns organizations" do
          formatted_organizations = [
            {
              org_title: 'Worker Person',
              org_name: 'Example, Inc',
              primary: false,
              rel: 'other'
            }
          ]
          expect(@contact_v3.organizations).to eq(formatted_organizations)
        end
      end

      context "when organizations is not specified" do
        it "returns an empty array" do
          expect(@empty.organizations).to eq([])
        end
      end
    end

    describe "#emails_full" do
      context "when emails are specified" do
        it "returns emails" do
          expect(@contact_v3.emails_full).to eq([ { :primary => true, :address => 'johnsmith@example.com', :rel => 'other' } ])
        end
      end

      context "when emails is not specified" do
        it "returns an empty array" do
          expect(@empty.emails_full).to eq([])
        end
      end
    end

    describe '#group_memberships' do
      it "returns group memberships" do
        expect(@contact_v3.group_memberships).to eq(['http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/111'])
      end
    end

    describe "#deleted_group_memberships" do
      it "returns deleted group memberships" do
        expect(@contact_v3.deleted_group_memberships).to eq(['http://www.google.com/m8/feeds/groups/test.user%40gmail.com/base/222'])
      end
    end
  end

  # The Google Contacts API (https://developers.google.com/gdata/docs/2.0/elements)
  # specifies an optional yomi field for orgName, givenName, additionalName and familyName
  it 'handles Japanese yomigana "yomi" name values' do
    contact_params = {
      'gd$name' => {
        'gd$givenName' => {'$t' => 'John' },
        'gd$additionalName' => {'$t' => 'Text name', 'yomi' => 'And yomi chars' },
        'gd$familyName' => { 'yomi' => 'Yomi chars only' },
      },
      'gd$organization' => [{
        'rel' => 'http://schemas.google.com/g/2005#other',
        'primary' => 'true',
        'gd$orgName' => {
          'yomi' => 'Yomigana'
        }
      }],
    }
    contact = GoogleContactsApi::Contact.new(contact_params, nil, @api)

    expect(contact.given_name).to eq('John')
    expect(contact.given_name_yomi).to be_nil

    expect(contact.additional_name).to eq('Text name')
    expect(contact.additional_name_yomi).to eq('And yomi chars')

    expect(contact.family_name).to be_nil
    expect(contact.family_name_yomi).to eq('Yomi chars only')

    expect(contact.organizations.first[:org_name]).to be_nil
    expect(contact.organizations.first[:org_name_yomi]).to eq('Yomigana')
  end
end
