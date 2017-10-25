# https://github.com/mperham/sidekiq/wiki/Batches

class CsvImportBatchCallbackHandler
  def on_complete(status, options)
    initialize_from_options(options)

    begin
      number_of_failures = @import.file_row_failures.size
      number_of_successes = status.total - number_of_failures

      if number_of_failures.positive?
        @import_callback_handler.handle_failure(failures: number_of_failures, successes: number_of_successes)
      else
        @import_callback_handler.handle_success(successes: number_of_successes)
      end
    ensure
      @import_callback_handler.handle_complete
    end
  end

  private

  def initialize_from_options(options)
    options = options.with_indifferent_access
    @import = Import.find(options[:import_id])
    @import_callback_handler = ImportCallbackHandler.new(@import)
  end
end
