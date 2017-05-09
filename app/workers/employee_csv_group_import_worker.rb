class EmployeeCsvGroupImportWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed, queue: :api_import, retry: 0

  def perform(path, from, to)
    importer = EmployeeCsvImporter.new(path: path)

    importer.converted_data[from...to].each do |user_for_import|
      EmployeeCsvImportWorker.perform_in(1.second, user_for_import.cas_attributes)
    end
  end
end
