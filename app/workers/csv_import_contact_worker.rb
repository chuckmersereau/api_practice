class CsvImportContactWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api_csv_import_contact_worker

  def perform(import_id, csv_line)
    import = Import.find(import_id)

    begin
      csv_line = CSV.new(csv_line).first unless csv_line.is_a?(Array)
      csv_row = CSV::Row.new(import.file_headers.values, csv_line)
      CsvRowContactBuilder.new(csv_row: csv_row, import: import).build.save!
    rescue => exception
      Rollbar.error(exception) unless exception.is_a?(ActiveRecord::RecordInvalid)
      import.with_lock do
        import.file_row_failures << csv_line
        import.save!
      end
    end
  end
end
