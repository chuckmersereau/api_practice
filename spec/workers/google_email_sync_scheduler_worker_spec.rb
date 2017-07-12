require 'rails_helper'

describe GoogleEmailSyncSchedulerWorker do
  let!(:first_google_integration_with_email) { create(:google_integration, email_integration: true) }
  let!(:second_google_integration_with_email) { create(:google_integration, email_integration: true) }
  let!(:google_integration_without_email) { create(:google_integration, email_integration: false) }

  it 'schedules the jobs over 24 hours' do
    expect(AsyncScheduler).to receive(:schedule_worker_jobs_over_24h)
      .with(GoogleSyncDataWorker, [[first_google_integration_with_email.id, 'email'], [second_google_integration_with_email.id, 'email']])
    GoogleEmailSyncSchedulerWorker.new.perform
  end
end
