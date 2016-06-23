require 'spec_helper'

describe SyncGoogleContactsWorker do
  context 'Sync user\'s Google contacts' do
    let(:user) { create(:user_with_account) }
    let(:google_integration) do
      create(:google_integration,
             calendar_integration: false,
             contacts_integration: true,
             account_list: user.account_lists.first)
    end

    it 'runs sucessfully the worker ' do
      expect do
        subject.perform
      end.to_not raise_error
    end

    it 'calls the specified method on the given class' do
      subject.perform do
        expect(google_integration.account_list).to receive(:queue_sync_with_google_contacts)
      end
    end
  end
end
