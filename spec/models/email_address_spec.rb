require 'spec_helper'

describe EmailAddress do
  context '.add_for_person' do
    let(:person) { create(:person) }
    let(:address) { 'test@example.com' }

    it "should create an email address if it's new" do
      expect do
        EmailAddress.add_for_person(person,  email: address)
        person.email_addresses.first.email.should == address
      end.to change(EmailAddress, :count).from(0).to(1)
    end

    it "doesn't create an email address if it exists" do
      EmailAddress.add_for_person(person,  email: address)
      expect do
        EmailAddress.add_for_person(person,  email: address)
        person.email_addresses.first.email.should == address
      end.to_not change(EmailAddress, :count)
    end

    it 'does nothing when adding itself to a person' do
      email = EmailAddress.add_for_person(person,  email: address)
      expect do
        EmailAddress.add_for_person(person,  email: address, id: email.id)
      end.to_not change(EmailAddress, :count)
    end

    it 'sets only the first email to primary' do
      EmailAddress.add_for_person(person,  email: address)
      person.email_addresses.first.primary?.should == true
      EmailAddress.add_for_person(person,  email: 'foo' + address)
      person.email_addresses.last.primary?.should == false
    end

    it 'sets a prior email to not-primary if the new one is primary' do
      email1 = EmailAddress.add_for_person(person,  email: address)
      email1.primary?.should == true

      email2 = EmailAddress.add_for_person(person,  email: 'foo' + address, primary: true)
      email2.primary?.should == true
      email2.send(:ensure_only_one_primary)
      email1.reload.primary?.should == false
    end

    it 'gracefully handles duplicate emails on an unsaved person' do
      person = build(:person)
      email = 'test@example.com'

      person.email_address = { email: email }
      EmailAddress.add_for_person(person,  email: email)
      person.save
      person.email_addresses.first.email.should == email
      person.email_addresses.length.should == 1
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

    context '#sync_with_mail_chimp' do
      let!(:account_list) { create(:account_list) }
      let!(:mail_chimp_account) { create(:mail_chimp_account, account_list: account_list, active: true) }
      let!(:contact) { create(:contact, account_list: account_list, send_newsletter: 'Email') }
      let!(:email) { EmailAddress.add_for_person(person, email: address, primary: true) }

      before do
        contact.people << person
        email.reload
      end

      it 'queues an unsubscribe if an email address is changed to no longer valid' do
        expect_any_instance_of(MailChimpAccount).to receive(:queue_unsubscribe_email).with('test@example.com')
        email.update(historic: true)
      end
    end
  end
end
