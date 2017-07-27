require 'rails_helper'

describe EmailAddress do
  context '.add_for_person' do
    let(:person) { create(:person) }
    let(:address) { 'test@example.com' }

    include_examples 'updatable_only_when_source_is_mpdx_validation_examples', attributes: [:email, :remote_id, :location], factory_type: :email_address

    include_examples 'before_create_set_valid_values_based_on_source_examples', factory_type: :email_address

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
        { email: 'a@a.co, b@b.co', location: 'a' } => [{ email: 'a@a.co', location: 'a' }, { email: 'b@b.co', location: 'a' }],
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
end
