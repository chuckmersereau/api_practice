require 'async'

class MailChimpAccount < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options unique: true

  THRESHOLD_SIZE_FOR_BATCH_OPERATION = 3

  MAILCHIMP_MAX_ALLOWD_MERGE_FIELDS = 30

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
    return if primary_list_id == list_id
    contacts = contacts_with_email_addresses(contact_ids)
    compare_and_unsubscribe(contacts, list_id)
    export_to_list(list_id, contacts)
    setup_webhooks(list_id)
    save_appeal_list_info(list_id, appeal_id)
  end

  def save_appeal_list_info(appeal_list_id, appeal_id)
    build_mail_chimp_appeal_list unless mail_chimp_appeal_list
    mail_chimp_appeal_list.update(appeal_list_id: appeal_list_id, appeal_id: appeal_id)
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
       e.message =~ /username portion of the email address is invalid/)
  end

  def compare_and_unsubscribe(contacts, list_id)
    # compare and unsubscribe email addresses from the prev mail chimp appeal list not on
    # the current one.
    members_to_unsubscribe = list_emails(list_id) -
                             batch_params(contacts, list_id).map { |b| b[:EMAIL] }
    unsubscribe_list_batch(list_id, members_to_unsubscribe) if members_to_unsubscribe.present?
  end

  def unsubscribe_list_batch(list_id, members_to_unsubscribe)
    return if list_id.blank?

    if members_to_unsubscribe.size < THRESHOLD_SIZE_FOR_BATCH_OPERATION
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
    setup_webhooks(primary_list_id)

    # clear the member records to force a full export
    mail_chimp_members.where(list_id: primary_list_id).destroy_all
    mail_chimp_members.reload

    MailChimpImport.new(self).import_contacts
    MailChimpSync.new(self).sync_contacts
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

  def export_to_list(list_id, contacts)
    # Make sure we have an interest group for each status of partner set
    # to receive the newsletter
    statuses = contacts.map(&:status).compact.uniq
    add_status_groups(list_id, statuses)
    add_greeting_merge_variable(list_id)

    members_params = batch_params(contacts, list_id)
    list_batch_subscribe(id: list_id, batch: members_params)
    create_member_records(members_params, list_id)
  end

  def list_batch_subscribe(id:, batch:)
    if batch.size < THRESHOLD_SIZE_FOR_BATCH_OPERATION
      batch.each do |params|
        gb.lists(id).members(email_hash(params[:email_address])).upsert(body: params)
      end
    else
      operations = batch.map do |params|
        { method: 'PUT',
          path: "/lists/#{id}/members/#{email_hash(params[:email_address])}",
          body: params.to_json }
      end
      gb.batches.create(body: { operations: operations })
    end
  end

  def create_member_records(members_params, list_id)
    members_params.each do |params|
      member = mail_chimp_members.find_or_create_by(list_id: list_id,
                                                    email: params[:email_address])

      status = if params[:interests]
                 status_for_interest_id(params[:interests].invert[true])
               end

      member.update(first_name: params[:merge_fields][:FNAME],
                    last_name: params[:merge_fields][:LNAME],
                    greeting: params[:merge_fields][:GREETING],
                    status: status)
    end
  end

  def batch_params(contacts, list_id)
    batch = []

    contacts.each do |contact|
      # Make sure we don't try to add to a blank group
      contact.status = 'Partner - Pray' if contact.status.blank?

      contact.people.each do |person|
        params = {
          status_if_new: 'subscribed',
          email_address: person.primary_email_address.email,
          merge_fields: {
            EMAIL: person.primary_email_address.email, FNAME: person.first_name,
            LNAME: person.last_name, GREETING: contact.greeting
          }
        }
        params[:language] = contact.locale if contact.locale.present?

        if grouping_id.present? && list_id == primary_list_id
          params[:interests] = interests_for_status(contact.status)
        end

        batch << params
      end
    end

    batch
  end

  def add_greeting_merge_variable(list_id)
    merge_fields = gb.lists(list_id).merge_fields.retrieve['merge_fields']

    return if merge_fields.find { |m| m['tag'] == 'GREETING' } ||
              merge_fields.size == MAILCHIMP_MAX_ALLOWD_MERGE_FIELDS

    gb.lists(list_id).merge_fields.create(
      body: {
        tag: 'GREETING', name: _('Greeting'), type: 'text'
      }
    )
  rescue Gibbon::MailChimpError => e
    # Check for the race condition of another thread having already added this
    return if e.detail =~ /Merge Field .* already exists/

    # If you try to add a merge field when list has 30 already, it gives 500 err
    if e.status_code == 500
      # Log the error but don't re-raise it
      Rollbar.error(e)
      return
    end
    raise e
  end

  def add_status_groups(list_id, statuses)
    statuses = (statuses.select(&:present?) + ['Partner - Pray']).uniq

    grouping = nil # define grouping variable outside of block
    begin
      grouping = find_grouping(list_id)
      if grouping
        self.grouping_id = grouping['id']

        # make sure the grouping is hidden
        gb.lists(list_id).interest_categories(grouping_id)
          .update(body: { title: grouping['title'], type: 'hidden' })
      end
    rescue Gibbon::MailChimpError => e
      raise e unless e.message.include?('code 211') # This list does not have interest groups enabled (code 211)
    end
    unless grouping
      # create a new grouping
      gb.lists(list_id).interest_categories(grouping_id)
        .create(body: { title: _('Partner Status'), type: 'hidden' })
      grouping = find_grouping(list_id)
      self.grouping_id = grouping['id']
    end

    # Add any new groups
    groups = gb.lists(list_id).interest_categories(grouping_id).interests.retrieve['interests'].map { |i| i['name'] }
    create_interest_categories(statuses - groups, list_id)

    cache_status_interest_ids(list_id)

    save
  end

  def create_interest_categories(statuses, list_id)
    statuses.each do |group|
      gb.lists(list_id).interest_categories(grouping_id).interests.create(body: { name: group })
    end
  rescue Gibbon::MailChimpError => e
    raise unless e.status_code == 400 &&
                 e.detail =~ /Cannot add .* because it already exists on the list/
  end

  def cache_status_interest_ids(list_id = nil)
    list_id ||= primary_list_id
    interests = gb.lists(list_id).interest_categories(grouping_id).interests.retrieve['interests']
    interests.each do |interest|
      status_interest_ids[interest['name']] = interest['id']
    end
    save
  end

  def interests_for_status(contact_status)
    cache_status_interest_ids unless status_interest_ids.present?

    Hash[status_interest_ids.map do |status, interest_id|
      [interest_id, status == _(contact_status)]
    end]
  end

  def status_for_interest_id(interest_id)
    return unless interest_id
    cache_status_interest_ids unless status_interest_ids.present?
    status_interest_ids.invert[interest_id]
  end

  def find_grouping(list_id)
    groupings = gb.lists(list_id).interest_categories.retrieve['categories']
    groupings.find { |g| g['id'] == grouping_id } ||
      groupings.find { |g| g['title'] == _('Partner Status') }
  end

  def queue_export_if_list_changed
    queue_export_to_primary_list if changed.include?('primary_list_id')
  end

  def setup_webhooks(list_id)
    # Don't setup webhooks when developing on localhost because MailChimp can't
    # verify the URL and so it makes the sync fail
    return if Rails.env.development? &&
              Rails.application.routes.default_url_options[:host].include?('localhost')

    return if webhook_token.present? &&
              gb.lists(list_id).webhooks.retrieve['webhooks'].find { |w| w['url'] == webhook_url }

    update(webhook_token: SecureRandom.hex(32)) if webhook_token.blank?

    gb.lists(list_id).webhooks.create(
      body: {
        url: webhook_url,
        events: { subscribe: true, unsubscribe: true, profile: true, cleaned: true,
                  upemail: true, campaign: true },
        sources: { user: true, admin: true, api: false }
      }
    )
  end

  def webhook_url
    (Rails.env.development? ? 'http://' : 'https://') +
      Rails.application.routes.default_url_options[:host] + '/mail_chimp_webhook/' + webhook_token
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
    # This would require paging if there is an account with over 15000 emails,
    # but that seems quite unlikely for regular staff members.
    gb.lists(list_id).members.retrieve(params: { count: 15_000 })['members']
  end

  def list_member_info(list_id, emails)
    # The MailChimp API v3 doesn't provde an easy, syncronous way to retrieve
    # member info scoped to a set of email addresses, so just pull it all and
    # filter it for now.
    email_set = emails.to_set
    list_members(list_id).select { |m| m['email_address'].in?(email_set) }
  end

  private

  def email_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end
end
