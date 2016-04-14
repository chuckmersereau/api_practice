require 'spec_helper'

describe MailChimpAccount::AppealListHookHandler do
  let(:account_list) { create(:account_list) }
  let(:mc_account) { create(:mail_chimp_account, account_list: account_list) }
  let(:handler) { MailChimpAccount::AppealListHookHandler.new(mc_account) }

  context '#email_cleaned_hook' do
    it 'ignores it if the reason is abuse (user marking email as spam)' do
      expect(MailChimpAccount::EmailBounceHandler).to_not receive(:new)
      handler.email_cleaned_hook('t@t.co', 'abuse')
    end

    it 'passes along to email bounce handler if not abuse' do
      bounce_handler = double(handle_bounce: nil)
      allow(MailChimpAccount::EmailBounceHandler).to receive(:new) { bounce_handler }

      handler.email_cleaned_hook('t@t.co', 'hard')

      expect(bounce_handler).to have_received(:handle_bounce)
    end
  end

  context '#campaign_status_hook' do
    it 'ignores it if the status is not sent' do
      expect(mc_account).to_not receive(:queue_log_sent_campaign)
      handler.campaign_status_hook('1', 'not-sent', 'subject')
    end

    it 'queues it if the status is sent' do
      expect(mc_account).to receive(:queue_log_sent_campaign).with('1', 'subject')
      handler.campaign_status_hook('1', 'sent', 'subject')
    end
  end
end
