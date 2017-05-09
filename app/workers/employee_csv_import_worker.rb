class EmployeeCsvImportWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed, queue: :api_import, retry: 1

  def perform(cas_attributes)
    cas_attributes.deep_symbolize_keys!
    UserFromCasService.find_or_create(cas_attributes)
  end
end
