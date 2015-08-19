class SidekiqCronWorker
  include Sidekiq::Worker
  include JobDuplicateChecker

  sidekiq_options backtrace: true, unique: true

  def perform(action, *args)
    return if duplicate_job?(action, *args)
    klass, method = action.split('.')
    klass.constantize.send(method.to_sym)
  end
end
