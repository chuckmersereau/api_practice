class Admin::FixWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_admin_fix_worker, unique: :until_executed, retry: false

  def perform(fix_name, record_class, id)
    record = record_class.constantize.find_by!(id: id)
    "Admin::#{fix_name.camelize}Fix".constantize.new(record).fix
  end
end
