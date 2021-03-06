require 'rubygems/package'

# This class is used to check if there were any sync failures and email the user about them
class MailChimp::BatchResults
  attr_reader :mail_chimp_account, :account_list

  def initialize(mail_chimp_account)
    @mail_chimp_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
  end

  def check_batch(batch_id)
    MailChimp::ConnectionHandler.new(mail_chimp_account)
                                .call_mail_chimp(self, :check_batch!, batch_id, require_primary: false)
  end

  private

  def check_batch!(batch_id)
    batch_details = load_batch(batch_id)
    batch_has_finished?(batch_details)

    return if batch_details['errored_operations'].to_i.zero?

    operations = load_batch_json(batch_details['response_body_url'])

    # we currently only know how to respond to 400 responses
    errored_operations = operations.select { |op| op['status_code'] == 400 }
    emails_with_person_ids = errored_operations.each_with_object({}) do |operation, hash|
      email, people = process_failed_op(operation)
      hash[email] = people if people&.any?
    end

    send_email(emails_with_person_ids)
  end

  def batch_has_finished?(batch_details)
    raise LowerRetryWorker::RetryJobButNoRollbarError, 'batch not finished' unless batch_details['status'] == 'finished'
  end

  def load_batch(batch_id)
    gibbon.batches(batch_id).retrieve
  end

  def gibbon
    wrapper.gibbon
  end

  def wrapper
    @wrapper ||= MailChimp::GibbonWrapper.new(mail_chimp_account)
  end

  def load_batch_json(url)
    file = read_first_file_from_tar(url)
    JSON.parse(file) if file
  end

  def zip_reader(url)
    Zlib::GzipReader.new(Kernel.open(url))
  end

  def read_first_file_from_tar(url)
    gz = zip_reader(url)
    Gem::Package::TarReader.new(gz) do |tar|
      tar.each { |entry| return entry.read if entry.file? }
    end
  end

  def process_failed_op(operation)
    detail = JSON.parse(operation['response'])['detail']
    return invalid_email(detail) if matches_invalid(detail) || matches_cleaned(detail)
    unknown_failure(detail)
  end

  def matches_invalid(detail)
    detail.match?(/ looks fake or invalid, please enter a real email address.$/)
  end

  def matches_cleaned(detail)
    compliance_message = ' is in a compliance state due to unsubscribe, bounce, '\
                          'or compliance review and cannot be subscribed.'
    return false unless detail.match?(/#{compliance_message}$/)
    status = wrapper.list_member_info(@mail_chimp_account.primary_list_id, extract_email(detail)).dig(0, 'status')
    status == 'cleaned'
  rescue Gibbon::MailChimpError
    false
  end

  def extract_email(detail)
    detail.split(' ', 2)[0]
  end

  def unknown_failure(detail)
    email, message = detail.split(' ', 2)
    Rollbar.info(UncaughtMailchimpSubFailure.new(message),
                 email: email,
                 mail_chimp_account_id: @mail_chimp_account.id)
  end

  def invalid_email(detail)
    email = extract_email(detail)
    person_ids = account_list.people.joins(:primary_email_address).where(email_addresses: { email: email }).ids
    EmailAddress.where(person_id: person_ids, email: email).find_each { |e| e.update(historic: true) }
    [email, person_ids]
  end

  def send_email(emails_with_person_ids)
    return unless emails_with_person_ids.any?
    account_list.users.each do |user|
      MailChimpMailer.delay.invalid_email_addresses(account_list, user, emails_with_person_ids)
    end
  end

  class UncaughtMailchimpSubFailure < StandardError; end
end
