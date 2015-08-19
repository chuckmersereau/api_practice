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

  subject { MailChimpSync.new(mc_account) }

  context '#sync_adds_and_updates' do
    let!(:mc_member) do
      create(:mail_chimp_member, mail_chimp_account: mc_account)
    end

    before { add_person_email }

    it 'does not subscribe contacts in the member list with no changed fields' do
      expect(mc_account).to_not receive(:export_to_list)
      subject.sync_adds_and_updates
    end

    it 'subscribes contacts with changed fields' do
      contact.update(greeting: 'Custom greeting')
      expect(mc_account).to receive(:export_to_list).with('list1', [contact])
      subject.sync_adds_and_updates
    end

    it 'subscribes contacts not in the member list' do
      mc_member.destroy
      expect(mc_account).to receive(:export_to_list).with('list1', [contact])
      subject.sync_adds_and_updates
    end
  end

  context '#sync_deletes' do
    it 'unsubscribes emails to remove' do
      expect(subject).to receive(:emails_to_remove) { ['test@example.com'] }
      expect(mc_account).to receive(:unsubscribe_list_batch)
        .with('list1', ['test@example.com'])
      subject.sync_deletes
    end
  end

  context '#emails_to_remove' do
    it 'returns mail chimp member emails not on the newsletter' do
      expect(subject).to receive(:mc_member_emails) { %w(p1@cru.org p2@cru.org) }
      expect(subject).to receive(:newsletter_emails) { %w(p2@cru.org p3@cru.org) }
      expect(subject.emails_to_remove).to eq %w(p1@cru.org)
    end
  end

  context '#newsletter_emails' do
    before { add_person_email }

    it 'plucks the emails from newsletter contacts' do
      expect(subject.newsletter_emails).to eq ['john@example.com']
    end
  end

  def add_person_email
    person.email_address = { email: 'john@example.com', primary: true }
    person.save
    contact.people << person
  end
end
