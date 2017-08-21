class GoogleEmailSyncEnqueuerWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_google_email_sync_enqueuer_worker, unique: :until_executed

  def perform
    GoogleIntegration.where(email_integration: true).pluck(:id).each do |google_integration_id|
      GoogleSyncDataWorker.perform_async(google_integration_id, 'email')
    end
  end
end
