class SidekiqCronWorker
  include Sidekiq::Worker

  sidekiq_options backtrace: false, unique: true

  def perform(action)
    PaperTrail.whodunnit = 'SidekiqCronWorker'
    klass, method = action.split('.')
    klass.constantize.send(method.to_sym)
  end
end
