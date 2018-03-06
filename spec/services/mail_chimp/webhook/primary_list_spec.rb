require 'rails_helper'

describe MailChimp::Webhook::PrimaryList do
  EXAMPLE_EMAIL = 'a@example.com'.freeze

  let(:account_list) { create(:account_list) }
  let(:mail_chimp_account) do
    create(:mail_chimp_account, account_list: account_list, auto_log_campaigns: true)
  end
  let(:subject) { described_class.new(mail_chimp_account) }
  let(:contact) { create(:contact, account_list: account_list, send_newsletter: 'Email') }

  let(:first_email_address) { create(:email_address, email: EXAMPLE_EMAIL) }
  let!(:person) { create(:person, contacts: [contact], primary_email_address: first_email_address) }

  let(:second_email_address) { create(:email_address, email: 'b@example.com', person: person) }
  let(:delayed) { double(:delayed) }

  let(:mock_gibbon_wrapper) { double(:mock_gibbon_wrapper) }

  let(:list_id) { 'PrimaryListID' }

  context '#subscribe_hook' do
    it "queues an import for the new subscriber if it doesn't exist" do
      expect(MailChimp::MembersImportWorker).to receive(:perform_async).with(mail_chimp_account.id, ['j@t.co'])
      subject.subscribe_hook('j@t.co')
    end

    it 'updates existing contacts to the list of MPDX subscribers' do
      person.update(optout_enewsletter: true)
      contact.update(send_newsletter: 'None')

      subject.subscribe_hook(EXAMPLE_EMAIL)

      expect(person.reload.optout_enewsletter).to eq(false)
      expect(contact.reload.send_newsletter).to eq('Email')
    end
  end

  context '#unsubscribe_hook' do
    before do
      allow(MailChimp::GibbonWrapper).to receive(:new).and_return(mock_gibbon_wrapper)
      allow(mock_gibbon_wrapper).to receive(:list_member_info).and_return([
                                                                            {
                                                                              'unsubscribe_reason' => 'Unspecified',
                                                                              'status' => 'unsubscribed'
                                                                            }
                                                                          ])
    end

    it 'marks an unsubscribed person with opt out of enewsletter' do
      subject.unsubscribe_hook(EXAMPLE_EMAIL, 'manual', list_id)
      expect(person.reload.optout_enewsletter).to be_truthy
      expect(person.contact.send_newsletter).to eq(nil)
    end

    it 'does not mark as unsubscribed someone with that email but not as set primary' do
      first_email_address.update_column(:primary, false)
      create(:email_address, email: 'b@example.com', primary: true, person: person)
      subject.unsubscribe_hook(EXAMPLE_EMAIL, 'manual', list_id)
      expect(person.reload.optout_enewsletter).to be_falsey
      expect(person.contact.send_newsletter).to eq('Email')
    end

    it 'does not mark as unsubscribed someone that was unsubscribed by the user' do
      allow(mock_gibbon_wrapper).to receive(:list_member_info).and_return([
                                                                            {
                                                                              'unsubscribe_reason' => 'N/A (Unsubscribed by an admin)',
                                                                              'status' => 'unsubscribed'
                                                                            }
                                                                          ])

      subject.unsubscribe_hook(EXAMPLE_EMAIL, 'manual', list_id)
      expect(person.reload.optout_enewsletter).to be false
    end

    it 'updates send_newsletter if all people are opt out' do
      create(:person, contacts: [contact], optout_enewsletter: true)
      contact.update(send_newsletter: 'Both')

      expect do
        subject.unsubscribe_hook(EXAMPLE_EMAIL, 'manual', list_id)
      end.to change { contact.reload.send_newsletter }.to('Physical')
    end

    it "doesn't update send_newsletter if some people are still not opted out" do
      person2 = create(:person, contacts: [contact], optout_enewsletter: false)
      person2.email_addresses.create(email: 'test@gmail.com')

      expect do
        subject.unsubscribe_hook(EXAMPLE_EMAIL, 'manual', list_id)
      end.to_not change { contact.reload.send_newsletter }
    end

    it 'updates send_newsletter if non-opted out people have no email addresses' do
      person2 = create(:person, contacts: [contact], optout_enewsletter: false)
      person2.email_addresses.destroy_all

      expect do
        subject.unsubscribe_hook(EXAMPLE_EMAIL, 'manual', list_id)
      end.to change { contact.reload.send_newsletter }.to(nil)
    end

    it 'cleans up MailChimpMember of unsubscribed email' do
      MailChimpMember.find_or_create_by!(mail_chimp_account: mail_chimp_account, list_id: list_id, email: EXAMPLE_EMAIL)

      expect do
        subject.unsubscribe_hook(EXAMPLE_EMAIL, 'manual', list_id)
      end.to change(MailChimpMember, :count).by(-1)
    end
  end

  context '#email_update_hook' do
    it 'creates a new email address for the updated email if it is not there' do
      subject.email_update_hook(EXAMPLE_EMAIL, 'new@example.com')
      expect(person.reload.email_addresses.count).to eq(2)
      expect(person.email_addresses.find_by(email: EXAMPLE_EMAIL).primary).to be_falsey
      expect(person.email_addresses.find_by(email: 'new@example.com').primary).to be_truthy
    end

    it 'sets the new email address as primary if it is there' do
      create(:email_address, email: 'new@example.com', primary: false, person: person)
      subject.email_update_hook(EXAMPLE_EMAIL, 'new@example.com')
      expect(person.reload.email_addresses.count).to eq(2)
      expect(person.email_addresses.find_by(email: EXAMPLE_EMAIL).primary).to be_falsey
      expect(person.email_addresses.find_by(email: 'new@example.com').primary).to be_truthy
    end
  end

  context '#email_cleaned_hook' do
    it 'marks the cleaned email as no longer valid and not primary and queues a mailing' do
      expect(SubscriberCleanedMailer).to receive(:delay).and_return(delayed)
      expect(delayed).to receive(:subscriber_cleaned).with(account_list, first_email_address)

      subject.email_cleaned_hook(EXAMPLE_EMAIL, 'hard', list_id)
      expect(first_email_address.reload.historic).to be_truthy
      expect(first_email_address.primary).to be_falsey
    end

    it 'makes another valid email as primary but not as invalid' do
      second_email_address
      subject.email_cleaned_hook(EXAMPLE_EMAIL, 'hard', list_id)

      expect(first_email_address.reload.historic).to be_truthy
      expect(first_email_address.primary).to be_falsey

      expect(second_email_address.reload.historic).to be_falsey
      expect(second_email_address.primary).to be_truthy
    end

    it 'triggers the unsubscribe hook for an email marked as spam (abuse)' do
      expect(subject).to receive(:unsubscribe_hook).with(EXAMPLE_EMAIL, 'abuse', list_id).and_return(true)
      subject.email_cleaned_hook(EXAMPLE_EMAIL, 'abuse', list_id)
    end

    it 'cleans up MailChimpMember of cleaned email' do
      MailChimpMember.find_or_create_by!(mail_chimp_account: mail_chimp_account, list_id: list_id, email: EXAMPLE_EMAIL)

      expect do
        subject.email_cleaned_hook(EXAMPLE_EMAIL, 'hard', list_id)
      end.to change(MailChimpMember, :count).by(-1)
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
