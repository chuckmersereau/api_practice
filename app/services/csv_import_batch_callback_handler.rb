# https://github.com/mperham/sidekiq/wiki/Batches

class CsvImportBatchCallbackHandler
  def on_complete(status, options)
    initialize_from_options(options)

    begin
      if status.failures == 0
        @import_callback_handler.handle_success
      else
        @import_callback_handler.handle_failure
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
