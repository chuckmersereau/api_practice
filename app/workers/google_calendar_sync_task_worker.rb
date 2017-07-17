class GoogleCalendarSyncTaskWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_google_sync_data_worker, unique: :until_executed

  def perform(google_integration_id, task_id)
    GoogleIntegration.find(google_integration_id).calendar_integrator.sync_task(task_id)
  end
end
