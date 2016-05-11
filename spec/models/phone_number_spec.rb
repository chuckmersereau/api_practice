require 'spec_helper'

describe PhoneNumber do
  let(:user) do
    u = create(:user_with_account)
    u.account_lists.first.update(home_country: 'Australia')
    u
  end
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let(:person) { contact.people.create(first_name: 'test').reload }

  describe 'adding a phone number to a person' do
    it "creates a phone number normalized to home country if it's new" do
      expect do
        PhoneNumber.add_for_person(person, number: '(02) 7010 1111')
        phone_number = person.reload.phone_numbers.first
        expect(phone_number.number).to eq('+61270101111')
      end.to change(PhoneNumber, :count).from(0).to(1)
    end

    it 'accepts phone numbers with country code different from home country' do
      PhoneNumber.add_for_person(person, number: '+161712345678')
      expect(person.reload.phone_numbers.first.number).to eq('+161712345678')
    end

    it 'adds a number invalid for home country but without country code' do
      # In this case the user's home country is Australia, but the number they
      # are entering does not look like an Australian phone number. In that
      # case, at least normalize it in a consistent way to avoid duplicates
      # (note that there is no +1 on the number, just a + in front of the 617).
      PhoneNumber.add_for_person(person, number: '617-123-5678')
      expect(person.reload.phone_numbers.first.number).to eq('+6171235678')
    end

    it "doesn't create a phone number if it exists" do
      PhoneNumber.add_for_person(person, number: '213-345-2313')
      expect do
        PhoneNumber.add_for_person(person, number: '213-345-2313')
      end.to_not change(PhoneNumber, :count)
    end

    it "doesn't create a phone number if it exists in normalized form" do
      contact.account_list.update(home_country: 'United States')
      PhoneNumber.add_for_person(person, number: '+12133452313')
      expect do
        PhoneNumber.add_for_person(person, number: '213-345-2313')
      end.to_not change(PhoneNumber, :count)
    end

    it "doesn't create a phone number if it exists in non-normalized form" do
      PhoneNumber.add_for_person(person, number: '213-345-2313')
      person.phone_numbers.last.update_column(:number, '213-345-2313')
      expect do
        PhoneNumber.add_for_person(person, number: '213-345-2313')
      end.to_not change(PhoneNumber, :count)
    end

    it "doesn't duplicated numbers with different formats if home country nil" do
      contact.account_list.update(home_country: nil)
      PhoneNumber.add_for_person(person, number: '213-345-2313')
      expect do
        PhoneNumber.add_for_person(person, number: '(213) 345-2313')
      end.to_not change(PhoneNumber, :count)
    end

    it 'sets only the first phone number to primary' do
      PhoneNumber.add_for_person(person, number: '213-345-2313')
      expect(person.phone_numbers.first.primary?).to eq(true)
      PhoneNumber.add_for_person(person, number: '313-313-3142')
      expect(person.phone_numbers.last.primary?).to eq(false)
    end

    it 'sets a prior phone number to not-primary if the new one is primary' do
      phone1 = PhoneNumber.add_for_person(person, number: '213-345-2313')
      expect(phone1.primary?).to eq(true)

      phone2 = PhoneNumber.add_for_person(person, number: '313-313-3142', primary: true)
      expect(phone2.primary?).to eq(true)
      phone2.send(:ensure_only_one_primary)
      expect(phone1.reload.primary?).to eq(false)
    end
  end

  describe 'clean_up_number' do
    it 'should parse out the country code' do
      pn = PhoneNumber.add_for_person(person, number: '+44 12345532')
      pn.clean_up_number
      expect(pn.country_code).to eq('44')
    end

    it 'returns a number and extension when provided' do
      phone = PhoneNumber.add_for_person(person, number: '213-345-2313;23')
      phone.clean_up_number
      expect(phone.number).to eq('+12133452313;23')
    end

    it 'defaults to United States normalizating when user home country unset' do
      user.account_lists.first.update(home_country: '')
      phone = PhoneNumber.add_for_person(person, number: '213-345-2313;23')
      phone.clean_up_number
      expect(phone.number).to eq('+12133452313;23')
    end

    # Badly formatted numbers can be imported into MPDX by the TntMPD import.
    # Rather than cleaning those numbers to nil or not importing them from
    # TntMPD (or any other import that might skip validation), this will allow
    # the user to see the badly formatted numbers in MPDX and then fix them
    # gradually as they edit contacts.
    it 'leaves a number with non-digit characters in it as-is' do
      pn = PhoneNumber.add_for_person(person, number: 'none')
      pn.clean_up_number
      expect(pn.number).to eq 'none'
    end
  end

  describe 'validate phone number' do
    it 'allows numbers with non-numeric characters' do
      # The reason for this is that the Tnt import and donor system import will
      # sometimes have non-numeric values for phone numbers. We used to have
      # validation for phone numbers to match a regex but it caused more
      # problems in terms of failed imports than it helped with data
      # cleanliness.
      expect(PhoneNumber.new(number: 'asdf')).to be_valid
      expect(PhoneNumber.new(number: '(213)BAD-PHONE')).to be_valid
    end

    it 'allows international numbers not in strict phonelib database' do
      expect(PhoneNumber.new(number: '+6427751138')).to be_valid
    end
  end

  describe 'comparing numbers' do
    it 'returns true for two numbers that are the same except for formatting' do
      user.account_lists.first.update(home_country: 'United States')
      pn = PhoneNumber.add_for_person(person, number: '+16173194567')
      pn2 = PhoneNumber.add_for_person(person, number: '(617) 319-4567')
      expect(pn.reload).to eq(pn2.reload)
    end

    it 'return false for two numbers that are not the same' do
      pn = PhoneNumber.create(number: '6173191234')
      pn2 = PhoneNumber.create(number: '6173191235')
      expect(pn).to_not eq(pn2)
    end
  end
end
