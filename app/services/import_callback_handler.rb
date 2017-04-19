class ImportCallbackHandler
  def initialize(import)
    @import = import
    @account_list = @import.account_list
    @started_at = @import.import_started_at
  end

  def handle_start
    @import.update_columns(importing: true, import_started_at: Time.current)
  end

  def handle_success
    @account_list.queue_sync_with_google_contacts
    @account_list.mail_chimp_account.queue_export_to_primary_list if @account_list.valid_mail_chimp_account

    begin
      ImportMailer.delay.complete(@import)
    rescue => exception
      Rollbar.error(exception)
    end
  end

  def handle_failure
    ImportMailer.delay.failed(@import)
  rescue => exception
    Rollbar.error(exception)
  end

  def handle_complete
    @account_list.async_merge_contacts(@import.import_started_at)
    ContactSuggestedChangesUpdaterWorker.perform_async(@import.user_id, @import.import_started_at)
  ensure
    @import.update_columns(importing: false, import_completed_at: Time.current)
  end
end
