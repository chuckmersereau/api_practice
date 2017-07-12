class GoogleEmailSyncSchedulerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_google_email_sync_scheduler_worker

  def perform
    job_arguments = GoogleIntegration.where(email_integration: true).pluck(:id).collect do |google_integration_id|
      [google_integration_id, 'email']
    end
    AsyncScheduler.schedule_worker_jobs_over_24h(GoogleSyncDataWorker, job_arguments)
  end
end
