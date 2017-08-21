require 'rails_helper'

describe GoogleEmailSyncEnqueuerWorker do
  let!(:first_google_integration_with_email) { create(:google_integration, email_integration: true) }
  let!(:second_google_integration_with_email) { create(:google_integration, email_integration: true) }
  let!(:google_integration_without_email) { create(:google_integration, email_integration: false) }

  it 'queues the jobs' do
    expect(GoogleSyncDataWorker).to receive(:perform_async).with(first_google_integration_with_email.id, 'email')
    expect(GoogleSyncDataWorker).to receive(:perform_async).with(second_google_integration_with_email.id, 'email')
    expect(GoogleSyncDataWorker).to_not receive(:perform_async).with(google_integration_without_email.id, 'email')
    GoogleEmailSyncEnqueuerWorker.new.perform
  end
end
