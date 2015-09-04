require 'spec_helper'

describe MailChimpImport do
  let(:account_list) { create(:account_list) }
  let(:mc_account) do
    create(:mail_chimp_account, account_list: account_list, primary_list_id: 'list1')
  end
  subject { MailChimpImport.new(mc_account) }

  describe 'importing from mail chimp' do
    it 'sends mail chimp errors to the mail chimp account for handling' do
      err = Gibbon::MailChimpError.new
      expect(mc_account).to receive(:list_emails).and_raise(err)
      expect(mc_account).to receive(:handle_newsletter_mc_error).with(err)
      subject.import_contacts
    end

    it 'creates a new contact and person if not there' do
      stub_list_members(email: 'j@example.com', fname: 'John', lname: 'Doe')
      expect do
        subject.import_contacts
      end.to change(Contact, :count).by(1)
      contact = Contact.last
      expect(contact.status).to eq 'Partner - Pray'
      expect(contact.name).to eq 'Doe, John'
      expect(contact.people.count).to eq 1
      expect(contact.send_newsletter).to eq 'Email'
      person = contact.people.first
      expect(person.first_name).to eq('John')
      expect(person.last_name).to eq('Doe')
      expect(person.email_addresses.count).to eq 1
      email = person.email_addresses.first
      expect(email.email).to eq 'j@example.com'
      expect(email.primary).to be true
    end

    it 'handles a missing first name' do
      stub_list_members(email: 'j@example.com', lname: 'Doe')
      subject.import_contacts
      expect(Contact.last.name).to eq 'Doe'
      expect(Person.last.first_name).to eq 'J'
    end

    it 'handles a missing last name' do
      stub_list_members(email: 'j@example.com', fname: 'John')
      subject.import_contacts
      expect(Contact.last.name).to eq 'John'
      expect(Person.last.first_name).to eq 'John'
    end

    it 'generates names from the email if first and last missing' do
      stub_list_members(email: 'j.d@example.com')
      subject.import_contacts
      expect(Contact.last.name).to eq 'J D'
      expect(Person.last.first_name).to eq 'J D'
    end

    describe 'importing with an existing contact' do
      let(:contact) { create(:contact, account_list: account_list) }
      let(:person) { create(:person_with_email) }
      before do
        contact.people << person
      end

      describe 'for a contact that would not cause extra emails to be subscribed' do
        it 'subscribes if all people match by email/name, have no email or opted-out' do
          stub_list_members({ fname: 'John', lname: 'Smith', email: 'john@example.com' },
                            fname: 'Andy', lname: 'Test', email: 'a@t.co')

          opted_out = create(:person, optout_enewsletter: true, first_name: 'Bob')
          opted_out.email = 'optout@example.com'
          no_email = create(:person, first_name: 'Dan')
          matches_name = create(:person, first_name: 'Andy', last_name: 'Test')
          contact.people << [opted_out, no_email, matches_name]

          expect { subject.import_contacts }.to_not change(Contact, :count)
          expect(contact.people.count).to eq 4

          expect(matches_name.primary_email_address.email).to eq 'a@t.co'
          expect(contact.reload.send_newsletter).to eq 'Email'
        end

        it 'changes send newsletter Physical to Both when subscribed' do
          stub_list_members(fname: 'John', lname: 'Smith', email: 'john@example.com')
          contact.update(send_newsletter: 'Physical')
          expect { subject.import_contacts }.to_not change(Contact, :count)
          expect(contact.reload.send_newsletter).to eq 'Both'
        end

        it 'does not create new if contact gets newsletter and has unmatched person w/ email' do
          stub_list_members(fname: 'John', lname: 'Smith', email: 'john@example.com')
          contact.update(send_newsletter: 'Both')
          unmatched_person = create(:person, first_name: 'Joe')
          unmatched_person.email = 'j@t.co'
          contact.people << unmatched_person
          expect { subject.import_contacts }.to_not change(Contact, :count)
          expect(contact.people.count).to eq 2
        end
      end

      describe 'for a contact that would cause extra emails to be subscribed' do
        it 'creates a new contact if the matching email is not primary' do
          person.email_addresses.first.update_column(:primary, false)
          person.email_addresses << create(:email_address, primary: true,
                                                           email: 'not-john@example.com')
          stub_list_members(email: 'john@example.com')
          expect { subject.import_contacts }.to change(Contact, :count).by(1)
          expect(contact.send_newsletter).to be_blank
          new_contact = Contact.last
          expect(new_contact.send_newsletter).to eq 'Email'
          expect(new_contact.name).to eq 'John'
          expect(new_contact.notes).to eq 'Imported from MailChimp'
          new_person = new_contact.people.last
          expect(new_person.primary_email_address.email).to eq 'john@example.com'
        end

        it 'creates new if contact not on enewsletter and has an unmatched person w/ email' do
          stub_list_members(fname: 'John', lname: 'Smith', email: 'john@example.com')
          contact.update(send_newsletter: 'Physical')
          unmatched_person = create(:person, first_name: 'Joe')
          unmatched_person.email = 'j@t.co'
          contact.people << unmatched_person
          expect { subject.import_contacts }.to change(Contact, :count).by(1)
          new_contact = Contact.last
          expect(new_contact.name).to eq 'Smith, John'
        end

        it 'creates a new contact if same-named person has different primary email' do
          contact.update(name: 'Smith, John')
          stub_list_members(fname: 'John', lname: 'Smith', email: 'j2@t.co')
          expect { subject.import_contacts }.to change(Contact, :count).by(1)
          new_contact = Contact.last

          expect(new_contact.name).to eq 'Smith, John'
          expect(new_contact.people.first.primary_email_address.email).to eq 'j2@t.co'
        end
      end
    end

    def stub_list_members(*members)
      member_emails = members.map { |m| m[:email] }
      members_info = members.map do |member|
        merges = {}
        merges['FNAME'] = member[:fname] if member[:fname]
        merges['LNAME'] = member[:lname] if member[:lname]
        { 'email' => member[:email], 'merges' => merges }
      end
      expect(mc_account).to receive(:list_emails).with('list1') { member_emails }
      expect(mc_account).to receive(:list_member_info) do |list_id, emails|
        expect(list_id).to eq 'list1'
        expect(emails - member_emails).to be_empty
        members_info.select { |info| info['email'].in?(emails) }
      end
    end
  end

  context '.email_to_name' do
    it 'splits email user parts and capitalizes them' do
      [
        ['john@example.com', 'John'],
        ['john.doe@example.com', 'John Doe'],
        ['d-j_doe@example.com', 'D J Doe']
      ].each do |email, expected_name|
        expect(MailChimpImport.email_to_name(email)).to eq expected_name
      end
    end
  end
end
