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
end
