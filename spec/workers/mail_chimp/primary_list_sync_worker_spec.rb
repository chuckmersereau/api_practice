require 'rails_helper'

RSpec.describe MailChimp::PrimaryListSyncWorker do
  let(:mail_chimp_account) { build(:mail_chimp_account) }

  it 'starts the sync with primary list' do
    expect_any_instance_of(MailChimp::Syncer).to receive(:two_way_sync_with_primary_list)

    MailChimp::PrimaryListSyncWorker.new.perform(mail_chimp_account)
  end
end
