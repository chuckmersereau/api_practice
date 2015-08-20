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

  context '#sync_adds_and_updates' do
    it 'does not subscribe contacts in the member list with no changed fields' do
      expect(mc_account).to_not receive(:export_to_list)
      subject.sync_adds_and_updates(nil)
    end

    it 'subscribes contacts with changed fields' do
      contact.update(greeting: 'Custom greeting')
      expect(mc_account).to receive(:export_to_list).with('list1', [contact])
      subject.sync_adds_and_updates(nil)
    end

    it 'subscribes contacts not in the member list' do
      mc_member.destroy
      expect(mc_account).to receive(:export_to_list).with('list1', [contact])
      subject.sync_adds_and_updates(nil)
    end
  end

  context '#sync_deletes' do
    it 'unsubscribes emails to remove' do
      person.update(optout_enewsletter: true)
      expect(mc_account).to receive(:unsubscribe_list_batch)
        .with('list1', ['john@example.com'])
      subject.sync_deletes
    end
  end
end
