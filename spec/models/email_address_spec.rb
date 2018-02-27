require 'rails_helper'

describe EmailAddress do
  context '.add_for_person' do
    let(:person) { create(:person) }
    let(:address) { 'test@example.com' }
    let(:address_changed_case) { 'Test@example.com' }

    include_examples 'updatable_only_when_source_is_mpdx_validation_examples',
                     attributes: [:email, :remote_id, :location], factory_type: :email_address

    include_examples 'after_validate_set_source_to_mpdx_examples', factory_type: :email_address

    it "should create an email address if it's new" do
      expect do
        EmailAddress.add_for_person(person, email: address)
        expect(person.email_addresses.first.email).to eq(address)
      end.to change(EmailAddress, :count).from(0).to(1)
    end

    it "doesn't create an email address if it exists" do
      EmailAddress.add_for_person(person,  email: address)
      expect do
        EmailAddress.add_for_person(person, email: address)
        expect(person.email_addresses.first.email).to eq(address)
      end.to_not change(EmailAddress, :count)
    end

    it "doesn't create an email address if it exists - case insensitive" do
      person.email = address
      expect do
        person.email = address_changed_case
        person.save!
        expect(person.reload.email_addresses.first.email).to eq(address)
      end.to_not change(EmailAddress, :count)
    end

    it 'creates a duplicate email address if it is from an TntImport' do
      EmailAddress.add_for_person(person, email: address)
      expect do
        EmailAddress.add_for_person(person, email: address, source: 'TntImport')
        expect(person.email_addresses.first.email).to eq(address)
      end.to change(EmailAddress, :count).from(1).to(2)
    end

    it 'should be invalid if email address with different case already exists' do
      EmailAddress.add_for_person(person, email: address)
      email = EmailAddress.create(person: person, email: address_changed_case)
      expect(email.errors[:email]).to include('has already been taken')
    end

    it "doesn't create an email address if it exists and are both from TntImports" do
      EmailAddress.add_for_person(person,  email: address, source: 'TntImport')
      expect do
        EmailAddress.add_for_person(person, email: address, source: 'TntImport')
        expect(person.email_addresses.first.email).to eq(address)
      end.to_not change(EmailAddress, :count)
    end

    it 'does nothing when adding itself to a person' do
      email = EmailAddress.add_for_person(person, email: address)
      expect do
        EmailAddress.add_for_person(person, email: address, id: email.id)
      end.to_not change(EmailAddress, :count)
    end

    it 'sets only the first email to primary' do
      EmailAddress.add_for_person(person, email: address)
      expect(person.email_addresses.first.primary?).to eq(true)
      EmailAddress.add_for_person(person, email: 'foo' + address)
      expect(person.email_addresses.last.primary?).to eq(false)
    end

    it 'sets a prior email to not-primary if the new one is primary' do
      email1 = EmailAddress.add_for_person(person, email: address)
      expect(email1.primary?).to eq(true)

      email2 = EmailAddress.add_for_person(person, email: 'foo' + address, primary: true)
      expect(email2.primary?).to eq(true)
      email2.send(:ensure_only_one_primary)
      expect(email1.reload.primary?).to eq(false)
    end

    it 'gracefully handles duplicate emails on an unsaved person' do
      person = build(:person)
      email = 'test@example.com'

      person.email_address = { email: email }
      EmailAddress.add_for_person(person, email: email)
      person.save
      expect(person.email_addresses.first.email).to eq(email)
      expect(person.email_addresses.length).to eq(1)
    end

    it 'handles emails that differ by a zero-width chars on person.save(validate: false)' do
      create(:email_address, email: 'j@t.co', person: person)

      person.email_address = { email: "j\u200E\u200B@t.co\u200E\u200B", primary: true }
      person.save(validate: false)

      expect(person.reload.email_addresses.count).to eq 1
      expect(person.reload.email_addresses.first.email).to eq 'j@t.co'
    end
  end

  context '#clean_and_split_emails' do
    it 'splits emails by commas and semicolons, removes names and handles comma in name' do
      {
        '' => [],
        nil => [],
        'John Doe <a@a.co>' => ['a@a.co'],
        'John Doe<a@a.co>' => ['a@a.co'],
        '"John Doe <a@a.co' => ['a@a.co'],
        'a@a.co, b@b.co;c@c.co' => ['a@a.co', 'b@b.co', 'c@c.co'],
        '"Doe, John" <a@a.co>,b@b.co' => ['a@a.co', 'b@b.co'],
        'a@a.co; "Doe, John" <b@b.co>' => ['a@a.co', 'b@b.co'],
        'a@a.co; "Doe, John <b@b.co' => ['a@a.co', 'b@b.co'],
        'Doe, John <a@a.co>, b@b.co' => ['a@a.co', 'b@b.co'],
        'a@a.co; Doe, John <b@b.co>' => ['a@a.co', 'b@b.co']
      }.each do |email_str, expected_cleaned_and_split|
        expect(EmailAddress.clean_and_split_emails(email_str)).to eq(expected_cleaned_and_split)
      end
    end
  end

  context '#expand_and_clean_emails' do
    it 'expands the email field if it has multiple emails, makes only the first primary, keeps other attrs' do
      {
        { email: 'a@a.co', historic: true } => [{ email: 'a@a.co', historic: true }],
        { email: 'a@a.co, b@b.co', location: 'a' } => [
          { email: 'a@a.co', location: 'a' },
          { email: 'b@b.co', location: 'a' }
        ],
        { email: 'a@a.co; John Doe <b@b.co>', primary: true, location: 'b' } => [
          { email: 'a@a.co', primary: true, location: 'b' }, { email: 'b@b.co', primary: false, location: 'b' }
        ]
      }.each do |email_attrs, expected_expanded|
        expect(EmailAddress.expand_and_clean_emails(email_attrs)).to eq(expected_expanded)
      end
    end
  end

  it 'strips out whitespace and zero-width characters before saving email' do
    email = build(:email_address, email: "\t zero-width-spaces\u200B\u200E@t.co \n")
    email.save
    expect(email.email).to eq 'zero-width-spaces@t.co'
  end

  describe '#set_valid_values' do
    it "sets valid_values to true if this is the person's only email address, or the source is manual" do
      email_address_one = create(:email_address, source: 'not mpdx')
      expect(email_address_one.valid_values).to eq(true)
      expect(email_address_one.source).to_not eq(EmailAddress::MANUAL_SOURCE)
      email_address_two = create(:email_address, source: 'not mpdx', person: email_address_one.person)
      expect(email_address_two.valid_values).to eq(false)
      expect(email_address_two.source).to_not eq(EmailAddress::MANUAL_SOURCE)
      email_address_three =
        create(:email_address, source: EmailAddress::MANUAL_SOURCE, person: email_address_one.person)
      expect(email_address_three.valid_values).to eq(true)
    end
  end

  describe '#start_google_plus_account_fetcher_job' do
    it 'starts the GooglePlusAccountFetcherWorker job' do
      allow_any_instance_of(EmailAddress).to receive(:start_google_plus_account_fetcher_job).and_call_original

      expect(GooglePlusAccountFetcherWorker).to receive(:perform_async)

      create(:email_address)
    end
  end

  describe '#sync_with_mail_chimp_account' do
    let!(:mail_chimp_account) { build(:mail_chimp_account, primary_list_id: 'primary_list_id') }
    let!(:account_list) { create(:account_list, mail_chimp_account: mail_chimp_account) }
    let!(:contact) do
      create(
        :contact,
        primary_person: first_person,
        people: [second_person],
        account_list: account_list,
        send_newsletter: 'Email'
      )
    end
    let!(:first_person) { create(:person, primary_email_address: build(:email_address)) }
    let!(:second_person) { create(:person, email_addresses: [build(:email_address)]) }

    it 'syncs the contact when a primary email_address is added to a primary_person' do
      expect(MailChimp::ExportContactsWorker).to receive(:perform_async).with(
        mail_chimp_account.id, 'primary_list_id', [contact.id]
      )

      create(:email_address, person: first_person, primary: true)
    end

    it 'syncs the contact when a primary email_address is added to a secondary person' do
      expect(MailChimp::ExportContactsWorker).to receive(:perform_async).with(
        mail_chimp_account.id, 'primary_list_id', [contact.id]
      )

      create(:email_address, person: second_person, primary: true)
    end

    it 'does not sync the contact when a none primary email_address is added' do
      expect(MailChimp::ExportContactsWorker).not_to receive(:perform_async).with(
        mail_chimp_account.id, 'primary_list_id', [contact.id]
      )

      create(:email_address, person: first_person)
    end

    it 'syncs the contact when a primary_email_address is updated with a new email' do
      expect(MailChimp::ExportContactsWorker).to receive(:perform_async).with(
        mail_chimp_account.id, 'primary_list_id', [contact.id]
      )

      first_person.primary_email_address.reload.update(email: 'new@email.com')
    end

    it 'triggers sync when changing primary email address' do
      expect(MailChimp::ExportContactsWorker).to receive(:perform_async).with(
        mail_chimp_account.id, 'primary_list_id', [contact.id]
      )

      not_primary = first_person.email_addresses.create(email: 'spam@gmail.com')

      not_primary.update(primary: true)
    end
  end
end
