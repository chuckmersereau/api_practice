class SidekiqCronWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_sidekiq_cron_worker, unique: :until_executed

  def perform(action)
    PaperTrail.whodunnit = 'SidekiqCronWorker'
    klass, method = action.split('.')
    klass.constantize.send(method.to_sym)
  end
end
