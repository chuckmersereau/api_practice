# This class is used to log MPDX tasks when a MailChimp campaign email is sent.
class MailChimp::CampaignLogger
  attr_reader :mail_chimp_account, :account_list, :gibbon

  def initialize(mail_chimp_account)
    @mail_chimp_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
  end

  def log_sent_campaign(campaign_id, subject)
    return unless mail_chimp_account.auto_log_campaigns?

    campaign_send_time = fetch_campaign_send_time(campaign_id)

    log_sent_campaign!(campaign_id, subject, campaign_send_time)
  rescue Gibbon::MailChimpError => error
    return deactivate_account if invalid_key?(error)
    raise unless campaign_not_completely_sent?(error)

    if campaign_has_been_running_for_less_than_one_hour?(campaign_send_time)
      raise LowerRetryWorker::RetryJobButNoRollbarError
    end
  end

  private

  def log_sent_campaign!(campaign_id, subject, campaign_send_time)
    sent_emails = mail_chimp_reports(campaign_id).map do |mail_chimp_report|
      mail_chimp_report[:email_address]
    end

    contacts_with_sent_emails(sent_emails).find_each do |contact|
      create_campaign_activity(contact, subject, campaign_send_time)
    end
  end

  def gibbon
    @gibbon ||= MailChimp::GibbonWrapper.new(mail_chimp_account).gibbon
  end

  def contacts_with_sent_emails(sent_emails)
    account_list.contacts
                .joins(people: :primary_email_address)
                .where(email_addresses: { email: sent_emails })
  end

  def mail_chimp_reports(campaign_id)
    gibbon.reports(campaign_id)
          .sent_to
          .retrieve(params: { count: 15_000 }).with_indifferent_access[:sent_to]
  end

  def invalid_key?(error)
    MailChimp::ConnectionHandler::INVALID_KEY_ERROR_MESSAGES.any? do |error_part|
      error.message.include? error_part
    end
  end

  def campaign_not_completely_sent?(error)
    # Campaign stats are not available until the campaign has been completely
    # sent. (code 301)
    error.message.include?('code 301')
  end

  def campaign_has_been_running_for_less_than_one_hour?(campaign_send_time)
    # keep retrying the job for one hour then give up.
    (Time.now.utc - campaign_send_time) < 1.hour
  end

  def fetch_campaign_send_time(campaign_id)
    Time.parse(gibbon.campaigns(campaign_id).retrieve['send_time'] + ' UTC')
  end

  def create_campaign_activity(contact, subject, campaign_send_time)
    activity_attributes = {
      account_list: account_list,
      activity_type: 'Newsletter - Email',
      start_at: campaign_send_time,
      completed_at: campaign_send_time,
      completed: true,
      result: 'Completed',
      source: 'mailchimp',
      subject: "MailChimp: #{subject}",
      type: 'Task'
    }

    contact.tasks.find_or_create_by(activity_attributes)
  end

  def deactivate_account
    mail_chimp_account.update_column(:active, false)
  end
end
