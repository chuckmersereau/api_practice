require 'async'

class MailChimpAccount < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options unique: true

  COUNT_PER_PAGE = 100

  List = Struct.new(:id, :name)

  belongs_to :account_list
  has_one :mail_chimp_appeal_list, dependent: :destroy
  has_many :mail_chimp_members, dependent: :destroy

  attr_reader :validation_error

  validates :account_list_id, :api_key, presence: true
  validates :api_key, format: /\A\w+-us\d+\z/

  before_create :set_active
  after_save :queue_export_if_list_changed

  serialize :status_interest_ids, Hash
  serialize :tags_interest_ids, Hash

  def lists
    return [] unless api_key.present?
    @list_response ||= gb.lists.retrieve
    return [] unless @list_response['lists']
    @lists ||= @list_response['lists'].map { |l| List.new(l['id'], l['name']) }
  rescue Gibbon::MailChimpError, OpenSSL::SSL::SSLError, Faraday::SSLError
    []
  end

  def list(list_id)
    lists.find { |l| l.id == list_id }
  end

  def primary_list
    list(primary_list_id) if primary_list_id.present?
  end

  def validate_key
    return false unless api_key.present?
    begin
      @list_response ||= gb.lists.retrieve
      self.active = true
    rescue Gibbon::MailChimpError => e
      self.active = false
      @validation_error = e.detail
    end
    update_column(:active, active) unless new_record?
    active
  end

  def active_and_valid?
    active? && validate_key
  end

  def queue_sync_contacts(contact_ids)
    async(:call_mailchimp, :sync_contacts, contact_ids) unless importing
  end

  def queue_export_to_primary_list
    async(:call_mailchimp, :export_to_primary_list)
  end

  def queue_export_appeal_contacts(contact_ids, list_id, appeal_id)
    async(:call_mailchimp, :export_appeal_contacts, contact_ids, list_id, appeal_id)
  end

  def queue_log_sent_campaign(campaign_id, subject)
    return unless auto_log_campaigns
    async(:call_mailchimp, :log_sent_campaign, campaign_id, subject)
  end

  def queue_import_new_member(email)
    update(importing: true)
    async(:call_mailchimp, :import_new_member, email)
  ensure
    update(importing: false)
  end

  def import_new_member(email)
    MailChimpImport.new(self).import_members_by_emails([email])
  end

  def datacenter
    api_key.to_s.split('-').last
  end

  def log_sent_campaign(campaign_id, subject)
    sent_emails = gb.reports(campaign_id).sent_to
                    .retrieve(params: { count: 15_000 })['sent_to']
                  .map { |sent_to| sent_to['email_address'] }

    account_list.contacts.joins(people: :primary_email_address)
                .where(email_addresses: { email: sent_emails }).references(:email_addresses)
                .uniq.each { |contact| create_campaign_activity(contact, subject) }
  rescue Gibbon::MailChimpError => e
    raise e unless e.message.include?('code 301')
    # Campaign stats are not available until the campaign has been completely
    # sent. (code 301)
    # This erorr occurs either if the campaign really is in the midst of
    # sending or if the campaign is for some reason stuck in the "sending"
    # status, so keep retrying the job for one hour then give up.
    if Time.now.utc - campaign_send_time(campaign_id) < 1.hour
      raise LowerRetryWorker::RetryJobButNoRollbarError
    end
  end

  def campaign_send_time(campaign_id)
    Time.parse(campaign_info(campaign_id)['send_time'] + ' UTC')
  end

  def campaign_info(campaign_id)
    gb.campaigns(filters: { campaign_id: campaign_id })['data'][0]
  end

  def create_campaign_activity(contact, subject)
    contact.activities.create(
      account_list: account_list, subject: "MailChimp: #{subject}",
      completed: true, start_at: Time.now, completed_at: Time.now, type: 'Task',
      activity_type: 'Email', result: 'Completed', source: 'mailchimp')
  end

  def lists_available_for_appeals
    lists.select { |l| l.id != primary_list_id }
  end

  def lists_available_for_newsletters
    lists.select { |l| l.id != mail_chimp_appeal_list.try(:appeal_list_id) }
  end

  def export_appeal_contacts(contact_ids, list_id, appeal_id)
    MailChimpAccount::Exporter.new(self, list_id).export_appeal_contacts(contact_ids, appeal_id)
  end

  def sync_contacts(contact_ids)
    MailChimpSync.new(self).sync_contacts(contact_ids)
  end

  def call_mailchimp(method, *args)
    return if !active? || primary_list_id.blank?
    send(method, *args)
  rescue Gibbon::MailChimpError => e
    case
    when e.message.include?('API Key Disabled') || e.message.include?('code 104')
      update_column(:active, false)
      AccountMailer.invalid_mailchimp_key(account_list).deliver
    when e.status_code == 503
      # The server is temporarily unable
      raise LowerRetryWorker::RetryJobButNoRollbarError
    when e.status_code == 429
      # No more than 10 simultaneous connections allowed.
      raise LowerRetryWorker::RetryJobButNoRollbarError
    when e.message.include?('code -91') # A backend database error has occurred. Please try again later or report this issue. (code -91)
      # raise the exception and the background queue will retry
      raise e
    else
      raise e
    end
  end

  def handle_newsletter_mc_error(e)
    case
    when e.message.include?('code 250')
      # MMERGE3 must be provided - Please enter a value (code 250)
      # Notify user and nulify primary_list_id until they fix the problem
      update_column(:primary_list_id, nil)
      AccountMailer.mailchimp_required_merge_field(account_list).deliver
    when e.message.include?('code 200')
      # Invalid MailChimp List ID (code 200)
      update_column(:primary_list_id, nil)
    when self.class.invalid_email_error?(e)
      # Ignore invalid email failtures
    when e.message.include?('code 214')
      # The new email address "xxxxx@example.com" is already subscribed to this list
    else
      raise e
    end
  end

  def self.invalid_email_error?(e)
    e.status_code == 400 &&
      (e.message =~ /looks fake or invalid, please enter a real email/ ||
       e.message =~ /username portion of the email address is invalid/ ||
       e.message =~ /domain portion of the email address is invalid/)
  end

  def unsubscribe_list_batch(list_id, members_to_unsubscribe)
    return if list_id.blank?

    if members_to_unsubscribe.size < MailChimpAccount::Exporter::THRESHOLD_SIZE_FOR_BATCH_OPERATION
      members_to_unsubscribe.each do |email|
        begin
          gb.lists(list_id).members(email_hash(email)).delete
        rescue Gibbon::MailChimpError => e
          # status of 404 means member already deleted
          raise e unless e.status_code == 404
        end
      end
    else
      operations = members_to_unsubscribe.map do |email|
        { method: 'DELETE', path: "/lists/#{list_id}/members/#{email_hash(email)}" }
      end
      gb.batches.create(body: { operations: operations })
    end

    mail_chimp_members.where(list_id: list_id, email: members_to_unsubscribe).destroy_all
  end

  def export_to_primary_list
    update(importing: true)
    MailChimpAccount::Exporter.new(self).export_to_primary_list
  ensure
    update(importing: false)
  end

  def newsletter_emails
    newsletter_contacts_with_emails(nil).pluck('email_addresses.email')
  end

  def newsletter_contacts_with_emails(contact_ids)
    contacts_with_email_addresses(contact_ids)
      .where(send_newsletter: %w(Email Both))
      .where.not(people: { optout_enewsletter: true })
  end

  def contacts_with_email_addresses(contact_ids)
    contacts = account_list.contacts
    contacts = contacts.where(id: contact_ids) if contact_ids
    contacts.includes(people: :primary_email_address)
            .where.not(email_addresses: { historic: true })
            .references('email_addresses')
  end

  def export_to_list(contacts)
    MailChimpAccount::Exporter.new(self).export_to_list(contacts)
  end

  def queue_export_if_list_changed
    queue_export_to_primary_list if changed.include?('primary_list_id')
  end

  def set_active
    self.active = true
  end

  def gb
    @gb ||= Gibbon::Request.new(api_key: api_key)
    @gb.timeout = 600
    @gb
  end

  def list_emails(list_id)
    list_members(list_id).map { |l| l['email_address'] }
  end

  def list_members(list_id)
    page = list_members_page(list_id, 0)
    total_items = page['total_items'].to_i
    members = page['members']

    more_pages = (total_items / COUNT_PER_PAGE) - 1
    more_pages.times do |i|
      page = list_members_page(list_id, COUNT_PER_PAGE * (i + 1))
      members.push(*page['members'])
    end

    members
  end

  def list_member_info(list_id, emails)
    # The MailChimp API v3 doesn't provide an easy, syncronous way to retrieve
    # member info scoped to a set of email addresses, so just pull it all and
    # filter it for now.
    email_set = emails.to_set
    list_members(list_id).select { |m| m['email_address'].in?(email_set) }
  end

  private

  def list_members_page(list_id, offset)
    gb.lists(list_id).members.retrieve(
      params: { count: COUNT_PER_PAGE, offset: offset }
    )
  end

  def email_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end
end
