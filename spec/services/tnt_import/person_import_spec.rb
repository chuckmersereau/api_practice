require 'rails_helper'

describe TntImport::PersonImport do
  include TntImportHelpers

  let(:row) { tnt_import_parsed_xml_sample_contact_row }
  let(:prefix) { '' }
  let(:contact) { create(:contact) }
  let(:override) { true }
  let(:import) do
    TntImport::PersonImport.new(row, contact, prefix, override)
  end

  describe '#add_or_update_person' do
    it 'creates a person' do
      expect { import.import }.to change { Person.count }.from(0).to(1)
    end
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
      expect(person.email_addresses.order(:created_at).first.historic).to be true

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

    it 'imports deceased boolean value' do
      row = { 'Deceased' => 'true' }
      import.send(:update_person_attributes, person, row)
      expect(person.deceased).to eq(true)
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

  context '#update_person_social_media_accounts' do
    it 'creates the social accounts' do
      expect { import.import }.to change { Person.count }.from(0).to(1)
      person = Person.last
      expect(person.facebook_accounts.size).to eq 1
      expect(person.facebook_accounts.order(:created_at).first.username).to eq '@bobfacebook'
      expect(person.linkedin_accounts.size).to eq 1
      expect(person.linkedin_accounts.order(:created_at).first.public_url).to eq '@boblinkedin'
      expect(person.twitter_accounts.size).to eq 1
      expect(person.twitter_accounts.order(:created_at).first.screen_name).to eq '@bobtwitter'
      expect(person.websites.size).to eq 2
      expect(person.websites.order(:created_at).first.url).to eq 'www.bobwebpage.com'
      expect(person.websites.order(:created_at).second.url).to eq 'www.bobwebpage2.com'
    end

    context 'spouse' do
      let(:prefix) { 'Spouse' }

      it 'creates the social accounts' do
        expect { import.import }.to change { Person.count }.from(0).to(1)
        person = Person.last
        expect(person.facebook_accounts.size).to eq 1
        expect(person.facebook_accounts.order(:created_at).first.username).to eq '@helenfacebook'
        expect(person.linkedin_accounts.size).to eq 1
        expect(person.linkedin_accounts.order(:created_at).first.public_url).to eq '@helenlinkedin'
        expect(person.twitter_accounts.size).to eq 1
        expect(person.twitter_accounts.order(:created_at).first.screen_name).to eq '@helentwitter'
        expect(person.websites.size).to eq 2
        expect(person.websites.order(:created_at).first.url).to eq 'www.helenparr.com'
        expect(person.websites.order(:created_at).second.url).to eq 'www.helenparr2.com'
      end
    end

    context 'no social accounts' do
      before do
        %w(SocialWeb1 SocialWeb2 SocialWeb3 SocialWeb4 WebPage1 WebPage2).each do |key|
          row.delete(key)
          row.delete("Spouse#{key}")
        end
      end

      it 'does not create social accounts' do
        expect { import.import }.to change { Person.count }.from(0).to(1)
        person = Person.order(:created_at).last
        expect(person.facebook_accounts.size).to eq 0
        expect(person.linkedin_accounts.size).to eq 0
        expect(person.twitter_accounts.size).to eq 0
        expect(person.websites.size).to eq 0
      end
    end

    context 'full facebook url' do
      before do
        row['SocialWeb1'] = 'https://www.facebook.com/bobfacebook'
      end

      it 'condenses url before attempting to create' do
        expect { import.import }.to change { Person.count }.from(0).to(1)
        person = Person.last
        expect(person.facebook_accounts.size).to eq 1
        expect(person.facebook_accounts.order(:created_at).first.username).to eq 'bobfacebook'

        # re-run import to see if it tries to override the facebook account
        expect { import.import }.to_not change(Person::FacebookAccount, :count)
      end
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
    it 'imports basic fields for a person' do
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
        'AnniversaryYear' => '1994',
        'Profession' => 'Janitor',
        'SpouseProfession' => 'Custodian',
        'BusinessName' => 'Business A',
        'SpouseBusinessName' => 'Business 1'
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
      expect(person.occupation).to eq('Janitor')
      expect(person.employer).to eq('Business A')
    end

    context 'override == true' do
      let(:override) { true }

      it 'ensures import\'s primary person is set as the contact\'s #primary_person' do
        import.import
        TntImport::PersonImport.new(row, contact, 'Spouse', true).import

        spouse = contact.people.find { |p| p.id != contact.primary_person_id }
        contact.primary_person_id = spouse.id
        expect(contact.reload.primary_person.first_name).to eq 'Helen'

        import.import
        expect(contact.reload.primary_person.first_name).to eq 'Bob'
      end

      it 'overrides values previously set' do
        import.import
        TntImport::PersonImport.new(row, contact, 'Spouse', true).import
        spouse = contact.people.find { |p| p.id != contact.primary_person_id }

        spouse.update(occupation: 'Architect')

        expect do
          TntImport::PersonImport.new(row, contact, 'Spouse', override).import
        end.to change { spouse.reload.occupation }.to("Helen's Profession")
      end
    end

    context 'override == false' do
      let(:override) { false }

      it 'ensures import\'s primary person is set as the contact\'s #primary_person' do
        import.import
        TntImport::PersonImport.new(row, contact, 'Spouse', true).import

        spouse = contact.people.find { |p| p.id != contact.primary_person_id }
        contact.primary_person_id = spouse.id
        expect(contact.reload.primary_person.first_name).to eq 'Helen'

        import.import
        expect(contact.reload.primary_person.first_name).to eq 'Helen'
      end

      it 'does not change values previously set' do
        import.import
        TntImport::PersonImport.new(row, contact, 'Spouse', true).import
        spouse = contact.people.find { |p| p.id != contact.primary_person_id }

        spouse.update(occupation: 'Architect')

        expect do
          TntImport::PersonImport.new(row, contact, 'Spouse', override).import
        end.to_not change { spouse.reload.occupation }
      end
    end
  end

  it 'converts two digit years to four digits' do
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
      'BirthdayYear' => '89',
      'AnniversaryMonth' => '11',
      'AnniversaryDay' => '4',
      'AnniversaryYear' => '10'
    }
    person = Person.new
    person = import.send(:update_person_attributes, person, contact_row)
    expect(person.birthday_year).to eq(1989)
    expect(person.anniversary_year).to eq(2010)
  end
end
