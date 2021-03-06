# This class wraps the Mail Chimp API connection and handles most possible errors.
class MailChimp::ConnectionHandler
  INVALID_KEY_ERROR_MESSAGES = [
    'API Key Disabled',
    'This account has been deactivated.',
    'code 104',
    "Your API key may be invalid, or you've attempted to access the wrong datacenter."
  ].freeze

  attr_accessor :mail_chimp_account

  delegate :active,
           :primary_list_id,
           to: :mail_chimp_account

  def initialize(mail_chimp_account)
    @mail_chimp_account = mail_chimp_account
  end

  # you can include require_primary: false as an argument when calling
  # this to prevent it from returning when primary_list_id is blank
  def call_mail_chimp(object, method, *args)
    require_primary = args.last.delete(:require_primary) if args.last.is_a? Hash
    args.pop if args.last == {}
    return if inactive_account? || (primary_list_id.blank? && require_primary != false)

    mail_chimp_account.update(importing: true)

    object.send(method, *args)
  rescue Gibbon::MailChimpError => error
    handle_mail_chimp_error(error)
  ensure
    mail_chimp_account.update(importing: false)
  end

  private

  def handle_mail_chimp_error(error)
    @error = error

    handle_request_or_account_or_server_error
  end

  def handle_request_or_account_or_server_error
    return stop_trying_to_sync_and_send_invalid_api_key_email if api_key_disabled?
    return forget_primary_list_and_send_merge_field_explanation_email if invalid_merge_fields?
    return forget_primary_list if invalid_mail_chimp_list?
    return if invalid_email? || email_already_subscribed?

    handle_server_error
  end

  def handle_server_error
    if server_temporarily_unavailable? || number_of_connections_limit_reached?
      retry_without_alerting_rollbar
    else
      retry_while_alerting_rollbar
    end
  end

  def invalid_merge_fields?
    @error.message.include?('Your merge fields were invalid.')
  end

  def invalid_email?
    @error.status_code == 400 &&
      (@error.message =~ /looks fake or invalid, please enter a real email/ ||
       @error.message =~ /username portion of the email address is invalid/ ||
       @error.message =~ /domain portion of the email address is invalid/ ||
       @error.message =~ /An email address must contain a single @/)
  end

  def email_already_subscribed?
    @error.message.include?('code 214')
  end

  def api_key_disabled?
    INVALID_KEY_ERROR_MESSAGES.any? { |error| @error.message.include? error }
  end

  def server_temporarily_unavailable?
    @error.status_code.to_s == '503'
  end

  def number_of_connections_limit_reached?
    @error.status_code.to_s == '429'
  end

  def invalid_mail_chimp_list?
    return true if @error.message.include?('code 200')

    # check if primary list still exists. This is the best guess we have at why a 404 would be thrown
    @error.message.include?('The requested resource could not be found.') &&
      mail_chimp_account.primary_list_id.present? &&
      mail_chimp_account.gibbon_wrapper.list(mail_chimp_account.primary_list_id).nil?
  end

  def inactive_account?
    !active
  end

  def stop_trying_to_sync_and_send_invalid_api_key_email
    mail_chimp_account.update_column(:active, false)

    AccountMailer.delay.invalid_mailchimp_key(mail_chimp_account.account_list)
  end

  def retry_without_alerting_rollbar
    raise LowerRetryWorker::RetryJobButNoRollbarError
  end

  def retry_while_alerting_rollbar
    raise @error
  end

  def forget_primary_list_and_send_merge_field_explanation_email
    forget_primary_list
    AccountMailer.delay.mailchimp_required_merge_field(mail_chimp_account.account_list)
  end

  def forget_primary_list
    mail_chimp_account.update_column(:primary_list_id, nil)
  end
end
