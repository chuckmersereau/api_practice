require 'spec_helper'

describe MailChimpHookHandler do
  let(:account_list) { create(:account_list) }
  let(:mc_account) do
    create(:mail_chimp_account, account_list: account_list, auto_log_campaigns: true)
  end
  let(:handler) { MailChimpHookHandler.new(mc_account) }
  let(:contact) { create(:contact, account_list: account_list) }
  let(:person) { create(:person) }

  before do
    person.email_address = { email: 'a@example.com', primary: true }
    person.save
    contact.people << person
  end

  context '#unsubscribe_hook' do
    it 'marks an unsubscribed person with opt out of enewsletter' do
      handler.unsubscribe_hook('a@example.com')
      expect(person.reload.optout_enewsletter).to be_truthy
    end

    it 'does not mark as unsubscribed someone with that email but not as set primary' do
      person.email_addresses.first.update_column(:primary, false)
      person.email_address = { email: 'b@example.com', primary: true }
      person.save
      handler.unsubscribe_hook('a@example.com')
      expect(person.reload.optout_enewsletter).to be_falsey
    end
  end

  context '#email_update_hook' do
    it 'creates a new email address for the updated email if it is not there' do
      handler.email_update_hook('a@example.com', 'new@example.com')
      person.reload
      expect(person.email_addresses.count).to eq(2)
      expect(person.email_addresses.find_by(email: 'a@example.com').primary).to be_falsey
      expect(person.email_addresses.find_by(email: 'new@example.com').primary).to be_truthy
    end

    it 'sets the new email address as primary if it is there' do
      person.email_address = { email: 'new@example.com', primary: false }
      person.save
      handler.email_update_hook('a@example.com', 'new@example.com')
      person.reload
      expect(person.email_addresses.count).to eq(2)
      expect(person.email_addresses.find_by(email: 'a@example.com').primary).to be_falsey
      expect(person.email_addresses.find_by(email: 'new@example.com').primary).to be_truthy
    end
  end

  context '#email_cleaned_hook' do
    it 'marks the cleaned email as no longer valid and not primary and queues a mailing' do
      email = person.email_addresses.first
      delayed = double
      expect(SubscriberCleanedMailer).to receive(:delay).and_return(delayed)
      expect(delayed).to receive(:subscriber_cleaned).with(account_list, email)

      handler.email_cleaned_hook('a@example.com', 'hard')
      email.reload
      expect(email.historic).to be_truthy
      expect(email.primary).to be_falsey
    end

    it 'makes another valid email as primary but not as invalid' do
      email2 = create(:email_address, email: 'b@example.com', primary: false)
      person.email_addresses << email2
      handler.email_cleaned_hook('a@example.com', 'hard')

      email = person.email_addresses.first.reload
      expect(email.historic).to be_truthy
      expect(email.primary).to be_falsey

      email2.reload
      expect(email2.historic).to be_falsey
      expect(email2.primary).to be_truthy
    end

    it 'triggers the unsubscribe hook for an email marked as spam (abuse)' do
      expect(handler).to receive(:unsubscribe_hook).with('a@example.com')
      handler.email_cleaned_hook('a@example.com', 'abuse')
    end
  end

  context '#campaign_status_hook' do
    it 'does nothing if the status is not sent' do
      expect(mc_account).to_not receive(:queue_log_sent_campaign)
      handler.campaign_status_hook('campaign1', 'not-sent', 'subject')
    end

    it 'does nothing if the mail chimp account not set to auto-log campaigns' do
      mc_account.auto_log_campaigns = false
      expect(mc_account).to_not receive(:queue_log_sent_campaign)
      handler.campaign_status_hook('campaign1', 'sent', 'subject')
    end

    it 'asyncronously calls the mail chimp account to log the sent campaign' do
      expect(mc_account).to receive(:queue_log_sent_campaign).with('c1', 'subject')
      handler.campaign_status_hook('c1', 'sent', 'subject')
    end
  end
end
