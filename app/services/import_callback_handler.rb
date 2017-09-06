class ImportCallbackHandler
  def initialize(import)
    @import = import
    @account_list = @import.account_list
    @started_at = @import.import_started_at
  end

  def handle_start
    @import.update_columns(importing: true, import_started_at: Time.current)
  end

  def handle_success(successes: nil)
    @account_list.queue_sync_with_google_contacts

    if @account_list.valid_mail_chimp_account
      MailChimp::PrimaryListSyncWorker.perform_async(@account_list.mail_chimp_account.id)
    end

    begin
      ImportMailer.delay.success(@import, successes)
      @import.update_column(:error, nil)
    rescue => exception
      Rollbar.error(exception)
    end
  end

  def handle_failure(exception: nil, failures: nil, successes: nil)
    ImportMailer.delay.failed(@import, successes, failures)
    @import.update_column(:error, exception_to_text(exception))
  rescue => exception
    Rollbar.error(exception)
  end

  def handle_complete
    @account_list.async_merge_contacts(@import.import_started_at)
    ContactSuggestedChangesUpdaterWorker.perform_async(@import.user_id, @import.import_started_at)
  ensure
    @import.update_columns(importing: false, import_completed_at: Time.current)
  end

  private

  def exception_to_text(exception)
    return unless exception
    text = [exception.class, exception.message].compact.join(': ')
    [text, exception.backtrace&.join("\n")].compact.join("\n")
  end
end
