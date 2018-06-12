require 'rails_helper'

RSpec.describe MailChimp::Webhook::AppealList do
  let(:account_list) { create(:account_list) }
  let(:mail_chimp_account) { create(:mail_chimp_account, account_list: account_list) }
  let(:subject) { described_class.new(mail_chimp_account) }

  context '#email_cleaned_hook' do
    let(:bounce_handler) { double(handle_bounce: nil) }
    let(:email_bouncer_class) { MailChimp::Webhook::Base::EmailBounceHandler }

    it 'ignores it if the reason is abuse (user marking email as spam)' do
      expect(email_bouncer_class).to_not receive(:new)
      subject.email_cleaned_hook('t@t.co', 'abuse')
    end

    it 'passes along to email bounce handler if not abuse' do
      allow(email_bouncer_class).to receive(:new).and_return(bounce_handler)

      subject.email_cleaned_hook('t@t.co', 'hard')

      expect(bounce_handler).to have_received(:handle_bounce)
    end
  end

  context '#campaign_status_hook' do
    it 'ignores it if the status is not sent' do
      expect(MailChimp::CampaignLoggerWorker).to_not receive(:perform_async)
      subject.campaign_status_hook('1', 'not_sent', 'subject')
    end

    it 'queues it if the status is sent' do
      expect(MailChimp::CampaignLoggerWorker).to receive(:perform_async).with(mail_chimp_account.id, '1', 'subject')
      subject.campaign_status_hook('1', 'sent', 'subject')
    end
  end
end
