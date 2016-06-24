require 'spec_helper'

describe SyncGoogleContactsWorker, sidekiq: :testing_disabled do
  context 'Sync user\'s Google contacts' do
    let!(:user) { create(:user_with_account) }
    let!(:google_integration) do
      create(:google_integration,
             calendar_integration: false,
             contacts_integration: true,
             account_list: user.account_lists.first)
    end
    it 'queues the sync with Google contacts for the account list' do
      clear_uniqueness_locks
      expect do
        subject.perform
      end.to change(Sidekiq::ScheduledSet.new, :size).by(1)
      job = Sidekiq::ScheduledSet.new.to_a.first
      expect(job['class']).to eq 'AccountList'
      expect(job['args']).to contain_exactly(1, 'queue_sync_with_google_contacts')
    end
  end
end
