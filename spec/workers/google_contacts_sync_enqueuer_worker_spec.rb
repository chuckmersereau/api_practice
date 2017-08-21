require 'rails_helper'

describe GoogleContactsSyncEnqueuerWorker do
  context 'Sync users Google contacts' do
    let!(:user) { create(:user_with_account) }
    let!(:google_integration) do
      create(:google_integration,
             calendar_integration: false,
             contacts_integration: true,
             account_list: user.account_lists.first)
    end

    it 'queues the sync with Google contacts for the account list' do
      expect(GoogleSyncDataWorker).to receive(:perform_async).with(google_integration.id, 'contacts')
      subject.perform
    end
  end
end
