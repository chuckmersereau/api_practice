require 'spec_helper'

describe MailChimpSync do
  let(:account_list) { create(:account_list) }
  let(:mc_account) do
    create(:mail_chimp_account, account_list: account_list, primary_list_id: 'list1')
  end
  let(:contact) do
    create(:contact, account_list: account_list, send_newsletter: 'Email')
  end
  let(:person) { create(:person) }
  let!(:mc_member) do
    create(:mail_chimp_member, mail_chimp_account: mc_account)
  end

  subject { MailChimpSync.new(mc_account) }

  before do
    person.email_address = { email: 'john@example.com', primary: true }
    person.save
    contact.people << person
  end

  context '#sync_contacts' do
    it 'syncs adds, updates and deletes' do
      expect(subject).to receive(:sync_adds_and_updates).with([1])
      expect(subject).to receive(:sync_deletes)
      subject.sync_contacts([1])
    end

    it 'sets the primary_list_id to nil on a code 200 (no list) error' do
      stub_mc_error('Invalid MailChimp List ID (code 200)')
      subject.sync_contacts
      expect(mc_account.reload.primary_list_id).to be_nil
    end

    it 'notifies user and clears primary_list_id if required merge field missing' do
      stub_mc_error('MMERGE3 must be provided - Please enter a value (code 250)')

      email = double
      expect(AccountMailer).to receive(:mailchimp_required_merge_field)
        .with(account_list) { email }
      expect(email).to receive(:deliver)

      subject.sync_contacts
      expect(mc_account.reload.primary_list_id).to be_nil
    end

    it 'does nothing for specified benign error codes' do
      [502, 220, 214].each do |code|
        stub_mc_error("Error (code #{code})")
        subject.sync_contacts
      end
    end

    it 're-raises other mail chimp errors' do
      stub_mc_error('other error')
      expect { subject.sync_contacts }.to raise_error(Gibbon::MailChimpError)
    end

    def stub_mc_error(msg)
      expect(subject).to receive(:sync_adds_and_updates).and_raise(Gibbon::MailChimpError, msg)
    end
  end

  context '#sync_adds_and_updates' do
    it 'does not subscribe contacts in the member list with no changed fields' do
      expect(mc_account).to_not receive(:export_to_list)
      subject.sync_adds_and_updates(nil)
    end

    it 'does not subscribe if irrelevant fields changed' do
      contact.update(notes: 'new notes')
      person.update(marital_status: 'married')
      expect(mc_account).to_not receive(:export_to_list)
      subject.sync_adds_and_updates(nil)
    end

    describe 'subscribes contact when relevant field changed: ' do
      it 'greeting' do
        contact.update(greeting: 'Custom greeting')
        expect_contact_exported
      end
      it 'status' do
        contact.update(status: 'Partner - Special')
        expect_contact_exported
      end
      it 'first name' do
        person.update(first_name: 'not-john')
        expect_contact_exported
      end
      it 'last name' do
        person.update(last_name: 'not-smith')
        expect_contact_exported
      end
    end

    it 'subscribes contacts not in the member list' do
      mc_member.destroy
      expect_contact_exported
    end

    def expect_contact_exported
      expect(mc_account).to receive(:export_to_list).with('list1', [contact])
      subject.sync_adds_and_updates(nil)
    end
  end

  context '#sync_deletes' do
    it 'does not unsubscribe emails if they are still on the letter' do
      expect(mc_account).to_not receive(:unsubscribe_list_batch)
      subject.sync_deletes
    end

    describe 'unsubscribes emails if they are no longer on the letter by: ' do
      it 'person opting out of enewsletter' do
        person.update(optout_enewsletter: true)
        expect_unsubscribe
      end
      it 'contact no longer on the letter' do
        contact.update(send_newsletter: 'Physical')
        expect_unsubscribe
      end
      it 'email not primary any more' do
        person.email_addresses.first.update_column(:primary, false)
        expect_unsubscribe
      end
      it 'email no longer valid' do
        person.email_addresses.first.update_column(:historic, true)
        expect_unsubscribe
      end

      def expect_unsubscribe
        expect(mc_account).to receive(:unsubscribe_list_batch)
          .with('list1', ['john@example.com'])
        subject.sync_deletes
      end
    end
  end

  context '#newsletter_contacts_with_emails' do
    it 'excludes people not on the email newsletter' do
      contact.update(send_newsletter: 'Physical')
      expect(subject.newsletter_contacts_with_emails(nil).to_a).to be_empty
    end

    it 'excludes a person from the loaded contact association if opted-out' do
      opt_out_person = create(:person, optout_enewsletter: true)
      opt_out_person.email_address = { email: 'foo2@example.com', primary: true }
      opt_out_person.save
      contact.people << opt_out_person
      opt_out_person.update(optout_enewsletter: true)
    end
  end
end
