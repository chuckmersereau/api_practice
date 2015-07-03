require 'async'

class MailChimpAccount < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options unique: true

  List = Struct.new(:id, :name)

  belongs_to :account_list

  # attr_accessible :api_key, :primary_list_id
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

  def queue_export_to_primary_list
    async(:call_mailchimp, :setup_webhooks_and_subscribe_contacts)
  end

  def queue_subscribe_contact(contact)
    async(:call_mailchimp, :subscribe_contacts, contact.id)
  end

  def queue_subscribe_person(person)
    async(:call_mailchimp, :subscribe_person, person.id)
  end

  def queue_unsubscribe_email(email)
    async(:call_mailchimp, :unsubscribe_email, email)
  end

  def queue_update_email(old_email, new_email)
    return if old_email == new_email
    async(:call_mailchimp, :update_email, old_email, new_email)
  end

  def queue_unsubscribe_contact(contact)
    contact.people.each(&method(:queue_unsubscribe_person))
  end

  def queue_unsubscribe_person(person)
    person.email_addresses.each do |email_address|
      async(:call_mailchimp, :unsubscribe_email, email_address.email)
    end
  end

  def datacenter
    api_key.to_s.split('-').last
  end

  def appeals_lists
    lists.select { |a| a.id != primary_list_id }
  end

  # private

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

  def update_email(old_email, new_email)
    gb.list_update_member(id: primary_list_id, email_address: old_email, merge_vars: { EMAIL: new_email })
  rescue Gibbon::MailChimpError => e
    # The email address "xxxxx@example.com" does not belong to this list (code 215)
    # There is no record of "xxxxx@example.com" in the database (code 232)
    if e.message.include?('code 215') || e.message.include?('code 232')
      subscribe_email(new_email)
    else
      raise e unless e.message.include?('code 214') # The new email address "xxxxx@example.com" is already subscribed to this list and must be unsubscribed first. (code 214)
    end
  end

  def unsubscribe_email(email)
    return if email.blank? || primary_list_id.blank?
    gb.list_unsubscribe(id: primary_list_id, email_address: email,
                        send_goodbye: false, delete_member: true)
  rescue Gibbon::MailChimpError => e
    case
    when e.message.include?('code 232') || e.message.include?('code 215')
      # do nothing
    when e.message.include?('code 200')
      # Invalid MailChimp List ID
      update_column(:primary_list_id, nil)
    else
      raise e
    end
  end

  def subscribe_email(email)
    gb.list_subscribe(id: primary_list_id, email_address: email, update_existing: true,
                      double_optin: false, send_welcome: false, replace_interests: true)
  rescue Gibbon::MailChimpError => e
    case
    when e.message.include?('code 250') # FNAME must be provided - Please enter a value (code 250)
    when e.message.include?('code 214') # The new email address "xxxxx@example.com" is already subscribed to this list and must be unsubscribed first. (code 214)
    else
      raise e
    end
  end

  def subscribe_person(person_id)
    begin
      person = Person.find(person_id)
    rescue ActiveRecord::RecordNotFound
      # This person was deleted after the background job was created
      return false
    end

    return unless person.primary_email_address
    vars = { EMAIL: person.primary_email_address.email, FNAME: person.first_name,
             LNAME: person.last_name, GREETING: person.contact ? person.contact.greeting : '' }
    begin
      gb.list_subscribe(id: primary_list_id, email_address: vars[:EMAIL], update_existing: true,
                        double_optin: false, merge_vars: vars, send_welcome: false, replace_interests: true)
    rescue Gibbon::MailChimpError => e
      case
      when e.message.include?('code 250') # MMERGE3 must be provided - Please enter a value (code 250)
        # Notify user and nulify primary_list_id until they fix the problem
        update_column(:primary_list_id, nil)
        AccountMailer.mailchimp_required_merge_field(account_list).deliver
      when e.message.include?('code 200') # Invalid MailChimp List ID (code 200)
        # TODO: Notify user and nulify primary_list_id until they fix the problem
        update_column(:primary_list_id, nil)
      when e.message.include?('code 502') || e.message.include?('code 220')
        # Invalid Email Address: "Rajah Tony" <amrajah@gmail.com> (code 502)
        # "jake.adams.photo@gmail.cm" has been banned (code 220) - This is usually a typo in an email address
      else
        raise e
      end
    end
  end

  def setup_webhooks_and_subscribe_contacts
    setup_webhooks
    subscribe_contacts
  end

  def subscribe_contacts(contact_ids = nil)
    contacts = account_list.contacts
    contacts = contacts.where(id: contact_ids) if contact_ids

    contacts = contacts
               .includes(people: :primary_email_address)
               .where(send_newsletter: %w(Email Both))
               .where('email_addresses.email is not null')
               .references('email_addresses')

    export_to_list(primary_list_id, contacts.to_set)
  end

  def export_to_list(list_id, contacts)
    # Make sure we have an interest group for each status of partner set
    # to receive the newsletter
    statuses = contacts.map(&:status).compact.uniq

    add_status_groups(list_id, statuses)

    add_greeting_merge_variable(list_id)

    gb.list_batch_subscribe(id: list_id, batch: batch_params(contacts), update_existing: true,
                            double_optin: false, send_welcome: false, replace_interests: true)
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
    return unless $rollout.active?(:mailchimp_webhooks, account_list)
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

  def unsubscribe_hook(email)
    return unless $rollout.active?(:mailchimp_webhooks, account_list)
    # No need to trigger a callback because MailChimp has already unsubscribed this email
    account_list.people.joins(:email_addresses).where(email_addresses: { email: email, primary: true })
      .update_all(optout_enewsletter: true)
  end

  def email_update_hook(old_email, new_email)
    return unless $rollout.active?(:mailchimp_webhooks, account_list)
    ids_of_people_to_update = account_list.people.joins(:email_addresses)
                              .where(email_addresses: { email: old_email, primary: true }).pluck(:id)

    Person.where(id: ids_of_people_to_update).includes(:email_addresses).each do |person|
      old_email_record = person.email_addresses.find { |e| e.email == old_email }
      new_email_record = person.email_addresses.find { |e| e.email == new_email }

      if new_email_record
        new_email_record.primary = true
        old_email_record.primary = false
      else
        old_email_record.primary = false
        person.email_addresses << EmailAddress.new(email: new_email, primary: true)
      end
      person.save!
    end
  end

  def email_cleaned_hook(email, reason)
    return unless $rollout.active?(:mailchimp_webhooks, account_list)
    return unsubscribe_hook(email) if reason == 'abuse'

    emails = EmailAddress.joins(person: [:contacts])
             .where(contacts: { account_list_id: account_list.id }, email: email)

    emails.each do |email_to_clean|
      email_to_clean.update(historic: true, primary: false)

      # ensure other email is subscribed
      queue_subscribe_person(email_to_clean.person) if email_to_clean.person

      SubscriberCleanedMailer.delay.subscriber_cleaned(account_list, email_to_clean)
    end
  end

  def campaign_status_hook(_campaign_id, _status, _subject)
  end

  def set_active
    self.active = true
  end

  def gb
    @gb ||= Gibbon.new(api_key)
    @gb.timeout = 600
    @gb
  end
end
