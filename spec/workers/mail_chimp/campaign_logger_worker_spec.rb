require 'rails_helper'

RSpec.describe MailChimp::CampaignLoggerWorker do
  let(:mail_chimp_account) { build(:mail_chimp_account) }

  it 'logs the campaign' do
    expect_any_instance_of(MailChimp::CampaignLogger).to receive(:log_sent_campaign).with(1, 'Subject')

    MailChimp::CampaignLoggerWorker.new.perform(mail_chimp_account, 1, 'Subject')
  end
end
