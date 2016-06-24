require 'spec_helper'

describe SyncGoogleContactsWorker do
  context 'Sync user\'s Google contacts' do
    let!(:user) { create(:user_with_account) }
    let!(:google_integration) do
      create(:google_integration,
             calendar_integration: false,
             contacts_integration: true,
             account_list: user.account_lists.first)
    end

    it 'queues the sync with Google contacts for the account list' do
      expect do
        subject.perform
      end.to change(LowerRetryWorker.jobs, :count).by(1)
      expect(LowerRetryWorker.jobs.last['args']).to eq google_integration.account_list.queue_sync_with_google_contacts
    end
  end
end
