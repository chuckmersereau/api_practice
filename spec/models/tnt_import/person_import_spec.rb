require 'spec_helper'

describe TntImport::PersonImport do
  let(:import) do
    contact = create(:contact)
    account_list = contact.account_list
    prefix = ''
    override = true
    TntImport::PersonImport.new(account_list, contact, prefix, override)
  end

  context '#update_person_emails' do
    let(:person) { create(:person) }

    it 'imports emails and sets the first preferred and valid one to primary' do
      row = { 'SpouseEmail1' => 'a@a.com', 'SpouseEmail2' => 'b@b.com', 'SpouseEmail3' => 'c@c.com',
              'SpouseEmail1IsValid' => 'true', 'SpouseEmail2IsValid' => 'false', 'SpouseEmail3IsValid' => 'true' }
      prefix = 'Spouse'
      expect(import).to receive(:tnt_email_preferred?).and_return(false, true)
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.size).to eq(3)
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['a@a.com', false])
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['b@b.com', false])
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['c@c.com', true])
    end

    it 'only marks one email as primary even if there are multiple that are preferred and valid' do
      prefix = ''
      row = { 'Email1' => 'a@a.com', 'Email2' => 'b@b.com', 'Email1IsValid' => 'true', 'Email2IsValid' => 'true' }
      expect(import).to receive(:tnt_email_preferred?).at_least(:once).and_return(true)
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.size).to eq(2)
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['a@a.com', true])
      expect(person.email_addresses.map { |e| [e.email, e.primary] }).to include(['b@b.com', false])
    end

    it 'marks tnt "invalid" email addresses as historic in mpdx' do
      prefix = ''
      row = { 'Email1' => 'a@a.com', 'Email1IsValid' => 'false' }
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.first.historic).to be true

      person.email_addresses.destroy_all

      prefix = 'Spouse'
      row = { 'SpouseEmail1' => 'a@a.com', 'SpouseEmail2' => 'b@b.com',
              'SpouseEmail1IsValid' => 'true', 'SpouseEmail2IsValid' => 'false' }
      import.send(:update_person_emails, person, row, prefix)
      expect(person.email_addresses.count).to eq(2)
      expect(person.email_addresses.map { |e| [e.email, e.historic] }).to include(['a@a.com', false])
      expect(person.email_addresses.map { |e| [e.email, e.historic] }).to include(['b@b.com', true])
    end

    it 'removes the name formatting and splits multiple emails in a field' do
      row = {
        'Email1' => 'John Doe <a@a.com>, "Doe, John" <b@b.com; c@c.com',
        'Email1IsValid' => 'true', 'PreferredEmailTypes' => '1'
      }
      expect do
        import.send(:update_person_emails, person, row, '')
      end.to change(person.email_addresses, :count).from(0).to(3)
      expect(person.email_addresses.pluck(:email).sort).to eq(['a@a.com', 'b@b.com', 'c@c.com'])
      expect(person.email_addresses.where(primary: true).count).to eq(1)
      expect(person.email_addresses.find_by(email: 'a@a.com').primary).to be true
    end
  end

  context '#update_person_phones' do
    let(:person) { create(:person) }

    it 'marks tnt "invalid" phone numbers as historic in mpdx' do
      row = { 'HomePhone2' => '212-222-2222', 'SpouseMobilePhone' => '313-333-3333',
              'PhoneIsValidMask' => '4096' }
      prefix = 'Spouse'
      import.send(:update_person_phones, person, row, prefix)
      expect(person.phone_numbers.count).to eq(2)
      expect(person.phone_numbers.map { |p| [p.number, p.historic] }).to include(['+12122222222', true])
      expect(person.phone_numbers.map { |p| [p.number, p.historic] }).to include(['+13133333333', false])
    end
  end

  context '#tnt_email_preferred?' do
    it 'interprets the tntmpd bit vector for PreferredEmailTypes to return true/false for prefix and email num' do
      {
        [{ 'PreferredEmailTypes' => '0' }, 1, ''] => false,
        [{ 'PreferredEmailTypes' => '0' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '2' }, 1, ''] => true,
        [{ 'PreferredEmailTypes' => '2' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '6' }, 1, ''] => true,
        [{ 'PreferredEmailTypes' => '6' }, 2, ''] => true,
        [{ 'PreferredEmailTypes' => '8' }, 1, ''] => false,
        [{ 'PreferredEmailTypes' => '8' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '8' }, 3, ''] => true,
        [{ 'PreferredEmailTypes' => '2' }, 1, 'Spouse'] => false,
        [{ 'PreferredEmailTypes' => '2' }, 1, 'Spouse'] => false,
        [{ 'PreferredEmailTypes' => '16' }, 1, 'Spouse'] => true,
        [{ 'PreferredEmailTypes' => '16' }, 2, 'Spouse'] => false,
        [{ 'PreferredEmailTypes' => '24' }, 1, 'Spouse'] => true,
        [{ 'PreferredEmailTypes' => '24' }, 2, ''] => false,
        [{ 'PreferredEmailTypes' => '24' }, 3, ''] => true,
        [{ 'PreferredEmailTypes' => '32' }, 2, 'Spouse'] => true
      }.each do |inputs, preferred|
        row, email_num, person_prefix = inputs
        expect(import.send(:tnt_email_preferred?, row, email_num, person_prefix)).to eq(preferred)
      end
    end
  end

  context '#update_person_attributes' do
    it 'imports a phone number for a person' do
      contact_row = {
        'PreferredPhoneType' => '0',
        'PhoneIsValidMask' => '4385',
        'PhoneCountryIDs' => '0=840',
        'HomePhone' => '(515) 555-1234',
        'MobilePhone' => '213-211-1111',
        'BusinessPhone' => '(515) 555-9771;ext=301',
        'SpouseMobilePhone' => '212-222-2222',
        'BirthdayMonth' => '9',
        'BirthdayDay' => '20',
        'BirthdayYear' => '1989',
        'AnniversaryMonth' => '11',
        'AnniversaryDay' => '4',
        'AnniversaryYear' => '1994'
      }
      person = Person.new
      expect do
        person = import.send(:update_person_attributes, person, contact_row)
      end.to change(person.phone_numbers, :length).by(3)
      expect(person.birthday_month).to eq(9)
      expect(person.birthday_day).to eq(20)
      expect(person.birthday_year).to eq(1989)
      expect(person.anniversary_month).to eq(11)
      expect(person.anniversary_day).to eq(4)
      expect(person.anniversary_year).to eq(1994)
    end
  end
end
