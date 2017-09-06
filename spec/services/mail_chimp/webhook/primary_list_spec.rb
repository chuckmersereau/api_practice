require 'rails_helper'

describe MailChimp::Webhook::PrimaryList do
  let(:account_list) { create(:account_list) }
  let(:mail_chimp_account) do
    create(:mail_chimp_account, account_list: account_list, auto_log_campaigns: true)
  end
  let(:subject) { described_class.new(mail_chimp_account) }
  let(:contact) { create(:contact, account_list: account_list) }

  let(:first_email_address) { create(:email_address, email: 'a@example.com') }
  let!(:person) { create(:person, contacts: [contact], primary_email_address: first_email_address) }

  let(:second_email_address) { create(:email_address, email: 'b@example.com', person: person) }
  let(:delayed) { double(:delayed) }

  context '#subscribe_hook' do
    it "queues an import for the new subscriber if it doesn't exist" do
      expect(MailChimp::MembersImportWorker).to receive(:perform_async).with(mail_chimp_account.id, ['j@t.co'])
      subject.subscribe_hook('j@t.co')
    end

    it 'updates existing contacts to the list of MPDX subscribers' do
      person.update(optout_enewsletter: true)
      contact.update(send_newsletter: 'None')

      subject.subscribe_hook('a@example.com')

      expect(person.reload.optout_enewsletter).to eq(false)
      expect(contact.reload.send_newsletter).to eq('Email')
    end
  end

  context '#unsubscribe_hook' do
    it 'marks an unsubscribed person with opt out of enewsletter' do
      subject.unsubscribe_hook('a@example.com')
      expect(person.reload.optout_enewsletter).to be_truthy
      expect(person.contact.send_newsletter).to eq(nil)
    end

    it 'does not mark as unsubscribed someone with that email but not as set primary' do
      first_email_address.update_column(:primary, false)
      create(:email_address, email: 'b@example.com', primary: true, person: person)
      subject.unsubscribe_hook('a@example.com')
      expect(person.reload.optout_enewsletter).to be_falsey
      expect(person.contact.send_newsletter).to eq(nil)
    end
  end

  context '#email_update_hook' do
    it 'creates a new email address for the updated email if it is not there' do
      subject.email_update_hook('a@example.com', 'new@example.com')
      expect(person.reload.email_addresses.count).to eq(2)
      expect(person.email_addresses.find_by(email: 'a@example.com').primary).to be_falsey
      expect(person.email_addresses.find_by(email: 'new@example.com').primary).to be_truthy
    end

    it 'sets the new email address as primary if it is there' do
      create(:email_address, email: 'new@example.com', primary: false, person: person)
      subject.email_update_hook('a@example.com', 'new@example.com')
      expect(person.reload.email_addresses.count).to eq(2)
      expect(person.email_addresses.find_by(email: 'a@example.com').primary).to be_falsey
      expect(person.email_addresses.find_by(email: 'new@example.com').primary).to be_truthy
    end
  end

  context '#email_cleaned_hook' do
    it 'marks the cleaned email as no longer valid and not primary and queues a mailing' do
      expect(SubscriberCleanedMailer).to receive(:delay).and_return(delayed)
      expect(delayed).to receive(:subscriber_cleaned).with(account_list, first_email_address)

      subject.email_cleaned_hook('a@example.com', 'hard')
      expect(first_email_address.reload.historic).to be_truthy
      expect(first_email_address.primary).to be_falsey
    end

    it 'makes another valid email as primary but not as invalid' do
      second_email_address
      subject.email_cleaned_hook('a@example.com', 'hard')

      expect(first_email_address.reload.historic).to be_truthy
      expect(first_email_address.primary).to be_falsey

      expect(second_email_address.reload.historic).to be_falsey
      expect(second_email_address.primary).to be_truthy
    end

    it 'triggers the unsubscribe hook for an email marked as spam (abuse)' do
      expect(subject).to receive(:unsubscribe_hook).with('a@example.com')
      subject.email_cleaned_hook('a@example.com', 'abuse')
    end
  end

  context '#campaign_status_hook' do
    it 'does nothing if the status is not sent' do
      expect(MailChimp::CampaignLoggerWorker).to_not receive(:perform_async)
      subject.campaign_status_hook('campaign1', 'not-sent', 'subject')
    end

    it 'asyncronously calls the mail chimp account to log the sent campaign' do
      expect(MailChimp::CampaignLoggerWorker).to receive(:perform_async).with(mail_chimp_account.id, 'c1', 'subject')
      expect do
        subject.campaign_status_hook('c1', 'sent', 'subject')
      end.to change { mail_chimp_account.reload.prayer_letter_last_sent }
    end
  end
end
