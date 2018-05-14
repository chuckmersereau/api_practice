class CsvImportContactWorker
  include Sidekiq::Worker

  MAX_RETRIES = 3

  sidekiq_options queue: :api_csv_import_contact_worker, retries: MAX_RETRIES

  def initialize
    @retries = 0
  end

  def perform(import_id, csv_headers, csv_fields)
    import = Import.find(import_id)
    csv_row = CSV::Row.new(csv_headers, csv_fields)

    begin
      CsvRowContactBuilder.new(csv_row: csv_row, import: import).build.save!

    rescue StandardError => exception
      if retryable_exception?(exception)
        Rollbar.error(exception)
        @retries += 1
        retry if @retries <= MAX_RETRIES
      end

      import.with_lock do
        import.file_row_failures << [message_for_exception(exception)] + csv_fields
        import.save!
      end
    end
  end

  private

  def retryable_exception?(exception)
    !exception.is_a?(ActiveRecord::RecordInvalid) &&
      !exception.is_a?(ActiveRecord::RecordNotUnique)
  end

  def message_for_exception(exception)
    if exception.is_a?(ActiveRecord::RecordNotUnique)
      'Record not unique error: Please ensure you are not importing duplicate '\
      'data (such as duplicate email addresses, which must be unique)'
    else
      exception.message
    end
  end
end
