# This class is used to log MPDX tasks when a MailChimp campaign email is sent.
class MailChimp::CampaignLogger
  attr_reader :mail_chimp_account, :account_list, :gibbon

  def initialize(mail_chimp_account)
    @mail_chimp_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
  end

  def log_sent_campaign(campaign_id, subject)
    log_sent_campaign!(campaign_id, subject)
  rescue Gibbon::MailChimpError => error
    raise unless campaign_not_completely_sent?(error)

    if campaign_has_been_running_for_less_than_one_hour?(campaign_id)
      raise LowerRetryWorker::RetryJobButNoRollbarError
    end
  end

  private

  def log_sent_campaign!(campaign_id, subject)
    sent_emails = mail_chimp_reports(campaign_id).map do |mail_chimp_report|
      mail_chimp_report[:email_address]
    end

    contacts_with_sent_emails(sent_emails).find_each do |contact|
      create_campaign_activity(contact, subject)
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

  def campaign_not_completely_sent?(error)
    # Campaign stats are not available until the campaign has been completely
    # sent. (code 301)
    error.message.include?('code 301')
  end

  def campaign_has_been_running_for_less_than_one_hour?(campaign_id)
    # keep retrying the job for one hour then give up.
    (Time.now.utc - campaign_send_time(campaign_id)) < 1.hour
  end

  def campaign_send_time(campaign_id)
    Time.parse(campaign_info(campaign_id)['send_time'] + ' UTC')
  end

  def campaign_info(campaign_id)
    gibbon.campaigns(filters: { campaign_id: campaign_id })['data'][0]
  end

  def create_campaign_activity(contact, subject)
    contact.tasks.create(
      account_list: account_list,
      activity_type: 'Newsletter - Email',
      completed: true,
      completed_at: Time.now,
      result: 'Completed',
      source: 'mailchimp',
      start_at: Time.now,
      subject: "MailChimp: #{subject}",
      type: 'Task'
    )
  end
end
