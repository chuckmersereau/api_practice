require 'async'

class MailChimpAccount < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options unique: true

  List = Struct.new(:id, :name)

  belongs_to :account_list
  has_one :mail_chimp_appeal_list, dependent: :destroy
  has_many :mail_chimp_members, dependent: :destroy

  attr_reader :validation_error

  validates :account_list_id, :api_key, presence: true
  validates :api_key, format: /\A\w+-us\d+\z/

  before_create :set_active
  after_save :queue_import_if_list_changed

  def lists
    return [] unless api_key.present?
    @list_response ||= gb.lists
    return [] unless @list_response['data']
    @lists ||= @list_response['data'].map { |l| List.new(l['id'], l['name']) }
  rescue Gibbon::MailChimpError
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
      @list_response ||= gb.lists
      self.active = true
    rescue Gibbon::MailChimpError => e
      self.active = false
      @validation_error = e.message
    end
    update_column(:active, active) unless new_record?
    active
  end

  def active_and_valid?
    active? && validate_key
  end

  def notify_contacts_changed(_contact_ids)
    async(:call_mailchimp, :sync_contacts)
  end

  def queue_export_to_primary_list
    async(:call_mailchimp, :setup_webhooks_and_subscribe_contacts)
  end

  def queue_export_appeal_contacts(contact_ids, list_id, appeal_id)
    async(:call_mailchimp, :export_appeal_contacts, contact_ids, list_id, appeal_id)
  end

  def datacenter
    api_key.to_s.split('-').last
  end

  def lists_available_for_appeals
    lists.select { |l| l.id != primary_list_id }
  end

  def lists_available_for_newsletters
    lists.select { |l| l.id != mail_chimp_appeal_list.try(:appeal_list_id) }
  end

  def export_appeal_contacts(contact_ids, list_id, appeal_id)
    return if primary_list_id == list_id
    contacts = contacts_with_email_addresses(contact_ids, false)
    compare_and_unsubscribe(contacts, list_id)
    export_to_list(list_id, contacts)
    save_appeal_list_info(list_id, appeal_id)
  end

  def save_appeal_list_info(appeal_list_id, appeal_id)
    build_mail_chimp_appeal_list unless mail_chimp_appeal_list
    mail_chimp_appeal_list.update(appeal_list_id: appeal_list_id, appeal_id: appeal_id)
  end

  # private

  def sync_contacts
    MailChimpSync.new(self).sync_contacts
  end

  def call_mailchimp(method, *args)
    return if !active? || primary_list_id.blank?
    send(method, *args)
  rescue Gibbon::MailChimpError => e
    case
    when e.message.include?('API Key Disabled') || e.message.include?('code 104')
      update_column(:active, false)
      AccountMailer.invalid_mailchimp_key(account_list).deliver
    when e.message.include?('code -50') # No more than 10 simultaneous connections allowed.
      raise LowerRetryWorker::RetryJobButNoAirbrakeError
    when e.message.include?('code -91') # A backend database error has occurred. Please try again later or report this issue. (code -91)
      # raise the exception and the background queue will retry
      raise e
    else
      raise e
    end
  end

  def compare_and_unsubscribe(contacts, list_id)
    # compare and unsubscribe email addresses from the prev mail chimp appeal list not on
    # the current one.
    members_to_unsubscribe = list_members(list_id).map { |l| l['email'] }.uniq -
                             batch_params(contacts).map { |b| b[:EMAIL] }
    unsubscribe_list_batch(list_id, members_to_unsubscribe) if members_to_unsubscribe.present?
  end

  def unsubscribe_list_batch(list_id, members_to_unsubscribe)
    return if list_id.blank?
    gb.list_batch_unsubscribe(id: list_id, emails: members_to_unsubscribe,
                              delete_member: true, send_goodbye: false, send_notify: false)
    mail_chimp_members.where(list_id: list_id, email: members_to_unsubscribe).destroy_all
  end

  def setup_webhooks_and_subscribe_contacts
    setup_webhooks
    # to force a full export, clear the member records
    mail_chimp_members.where(list_id: primary_list_id).destroy_all
    MailChimpSync.new(self).sync_contacts
  end

  def subscribe_contacts(contact_ids = nil, list_id = primary_list_id)
    contacts = contacts_with_email_addresses(contact_ids)
    export_to_list(list_id, contacts.to_set)
  end

  def contacts_with_email_addresses(contact_ids, enewsletter_only = true)
    contacts = account_list.contacts
    contacts = contacts.where(id: contact_ids) if contact_ids
    contacts = contacts.where(send_newsletter: %w(Email Both)) if enewsletter_only
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

    members_params = batch_params(contacts)
    gb.list_batch_subscribe(id: list_id, batch: members_params, update_existing: true,
                            double_optin: false, send_welcome: false, replace_interests: true)
    create_member_records(members_params)
  end

  def create_member_records(members_params)
    members_params.each do |params|
      member = mail_chimp_members.find_or_create_by(list_id: primary_list_id, email: params[:EMAIL])
      groupings = params[:GROUPINGS].try(:first)
      status = groupings ? groupings[:groups] : nil
      member.update(first_name: params[:FNAME], last_name: params[:LNAME],
                    greeting: params[:GREETING], status: status)
    end
  end

  def batch_params(contacts)
    batch = []

    contacts.each do |contact|
      # Make sure we don't try to add to a blank group
      contact.status = 'Partner - Pray' if contact.status.blank?

      contact.people.each do |person|
        next if person.primary_email_address.blank? || person.optout_enewsletter? ||
                person.primary_email_address.historic?

        batch << { EMAIL: person.primary_email_address.email, FNAME: person.first_name,
                   LNAME: person.last_name, GREETING: contact.greeting }
      end

      # if we have a grouping_id, add them to that group
      next unless grouping_id.present?
      batch.each { |p| p[:GROUPINGS] ||= [{ id: grouping_id, groups: _(contact.status) }] }
    end

    batch
  end

  def add_greeting_merge_variable(list_id)
    return if gb.list_merge_vars(id: list_id).find { |merge_var| merge_var['tag'] == 'GREETING' }
    gb.list_merge_var_add(id: list_id, tag: 'GREETING', name: 'Greeting')
  rescue Gibbon::MailChimpError => e
    raise e unless e.message.include?('code 254') # A Merge Field with the tag "GREETING" already exists for this list.
  end

  def add_status_groups(list_id, statuses)
    statuses = (statuses.select(&:present?) + ['Partner - Pray']).uniq

    grouping = nil # define grouping variable outside of block
    begin
      grouping = find_grouping(list_id)
      if grouping
        self.grouping_id = grouping['id']
        # make sure the grouping is hidden
        gb.list_interest_grouping_update(grouping_id: grouping_id, name: 'type', value: 'hidden')
      end
    rescue Gibbon::MailChimpError => e
      raise e unless e.message.include?('code 211') # This list does not have interest groups enabled (code 211)
    end
    # create a new grouping
    unless grouping
      gb.list_interest_grouping_add(id: list_id, name: _('Partner Status'), type: 'hidden',
                                    groups: statuses.map { |s| _(s) })
      grouping = find_grouping(list_id)
      self.grouping_id = grouping['id']
    end

    # Add any new groups
    groups = grouping['groups'].map { |g| g['name'] }

    (statuses - groups).each do |group|
      gb.list_interest_group_add(id: list_id, group_name: group, grouping_id: grouping_id)
    end

    save
  end

  def find_grouping(list_id)
    groupings = gb.list_interest_groupings(id: list_id)
    groupings.find { |g| g['id'] == grouping_id } ||
      groupings.find { |g| g['name'] == _('Partner Status') }
  end

  def queue_import_if_list_changed
    queue_export_to_primary_list if changed.include?('primary_list_id')
  end

  def setup_webhooks
    return if Rails.env.development?
    return if webhook_token.present? &&
              gb.list_webhooks(id: primary_list_id).find { |hook| hook['url'] == webhook_url }

    update(webhook_token: SecureRandom.hex(32))
    gb.list_webhook_add(id: primary_list_id, url: webhook_url,
                        actions: { subscribe: true, unsubscribe: true, profile: true, cleaned: true,
                                   upemail: true, campaign: true },
                        sources: { user: true, admin: true, api: false })
  end

  def webhook_url
    (Rails.env.development? ? 'http://' : 'https://') +
      Rails.application.routes.default_url_options[:host] + '/mail_chimp_webhook/' + webhook_token
  end

  def set_active
    self.active = true
  end

  def gb
    @gb ||= Gibbon.new(api_key)
    @gb.timeout = 600
    @gb
  end

  def list_members(list_id)
    gb.list_members(id: list_id)['data']
  end
end
