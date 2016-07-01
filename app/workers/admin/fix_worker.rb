class Admin::FixWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, retry: false, backtrace: false

  def perform(fix_name, record_class, id)
    record = record_class.constantize.find(id)
    "Admin::#{fix_name.camelize}Fix".constantize.new(record).fix
  end
end
