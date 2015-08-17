# This class provides the flexibility needed for one person to have
# multiple designation accounts in multiple countries. In that scenario
# it didn't make sense to associate a contact with a designation
# account. It also doesn't work to associate the contact with a user
# account because (for example) a husband and wife will both want to see
# the same contacts. So for most users, an AccountList will contain only
# one account, and the notion of an AccountList will be hidden from the
# user. This concept should only be exposed to users who have more than
# one designation account.

require 'async'
require 'mail'

class AccountList < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :import, retry: false, unique: true

  store :settings, accessors: [:monthly_goal, :tester, :owner, :account_list_country]

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_many :account_list_users, dependent: :destroy
  has_many :users, through: :account_list_users
  has_many :organization_accounts, through: :users
  has_many :account_list_entries, dependent: :destroy
  has_many :designation_accounts, through: :account_list_entries
  has_many :contacts, dependent: :destroy
  has_many :active_contacts, -> { where(Contact.active_conditions) }, class_name: 'Contact'
  has_many :notifications, through: :contacts
  has_many :addresses, through: :contacts
  has_many :people, through: :contacts
  has_many :active_people, through: :active_contacts, source: :people, class_name: 'Person'
  has_many :master_people, through: :people
  has_many :donor_accounts, through: :contacts
  has_many :company_partnerships, dependent: :destroy
  has_many :companies, through: :company_partnerships
  has_many :tasks
  has_many :activities, dependent: :destroy
  has_many :imports, dependent: :destroy
  has_many :account_list_invites, dependent: :destroy
  has_one :mail_chimp_account, dependent: :destroy
  has_many :notification_preferences, dependent: :destroy, autosave: true
  has_many :messages
  has_many :designation_profiles
  has_one :prayer_letters_account, dependent: :destroy, autosave: true
  has_one :pls_account, dependent: :destroy, autosave: true
  has_many :google_integrations, dependent: :destroy
  has_many :appeals
  has_many :help_requests
  has_many :recurring_recommendation_results

  accepts_nested_attributes_for :contacts, reject_if: :all_blank, allow_destroy: true

  after_update :subscribe_tester_to_mailchimp, :subscribe_owners_to_mailchimp

  def self.find_with_designation_numbers(numbers, organization)
    designation_account_ids = DesignationAccount.where(designation_number: numbers, organization_id: organization.id).pluck(:id).sort
    query = "select account_list_id,array_to_string(array_agg(designation_account_id), ',') as designation_account_ids from account_list_entries group by account_list_id"
    results = AccountList.connection.select_all(query)
    results.each do |hash|
      if hash['designation_account_ids'].split(',').map(&:to_i).sort == designation_account_ids
        return AccountList.find(hash['account_list_id'])
      end
    end
    nil
  end

  def monthly_goal=(val)
    settings[:monthly_goal] = val.to_s.gsub(/[^\d\.]/, '').to_i if val
  end

  def monthly_goal
    settings[:monthly_goal].present? && settings[:monthly_goal].to_i > 0 ? settings[:monthly_goal].to_i : nil
  end

  def account_list_country
    settings[:account_list_country].present? ? settings[:account_list_country] : 'None'
  end

  def multiple_designations
    designation_accounts.length > 1 ? true : false
  end

  def contact_tags
    @contact_tags ||= contacts.joins(:tags).order('tags.name').pluck('DISTINCT tags.name')
  end

  def activity_tags
    @activity_tags ||= activities.joins(:tags).order('tags.name').pluck('DISTINCT tags.name')
  end

  def cities
    @cities ||= contacts.active.joins(:addresses).order('addresses.city').pluck('DISTINCT addresses.city')
  end

  def states
    @states ||= contacts.active.joins(:addresses).order('addresses.state').pluck('DISTINCT addresses.state')
  end

  def regions
    @regions ||= contacts.active.joins(:addresses).order('addresses.region').pluck('DISTINCT addresses.region')
  end

  def metro_areas
    @metro_areas ||= contacts.active.joins(:addresses).order('addresses.metro_area').pluck('DISTINCT addresses.metro_area')
  end

  def countries
    @countries ||= contacts.active.joins(:addresses).order('addresses.country').pluck('DISTINCT addresses.country')
  end

  def churches
    @churches ||= contacts.order(:church_name).pluck('DISTINCT church_name')
  end

  def timezones
    @timezones ||= contacts.order(:timezone).pluck('DISTINCT timezone')
  end

  def valid_mail_chimp_account
    mail_chimp_account.try(:active?) && mail_chimp_account.primary_list.present?
  end

  def valid_prayer_letters_account
    prayer_letters_account.try(:valid_token?)
  end

  def valid_pls_account
    pls_account.try(:valid_token?)
  end

  def top_partners
    contacts.order('total_donations desc').where('total_donations > 0').limit(10)
  end

  def donations
    if designation_account_ids.present?
      Donation.where(donor_account_id: donor_account_ids, designation_account_id: designation_account_ids)
    else
      Donation.where(donor_account_id: donor_account_ids)
    end
  end

  def designation_profile(user)
    designation_profiles.where(user_id: user.id).last
  end

  def total_pledges
    @total_pledges ||= contacts.financial_partners.to_a.sum(&:monthly_pledge).round(2)
  end

  def received_pledges
    @received_pledges ||= contacts.financial_partners.where(pledge_received: true).to_a.sum(&:monthly_pledge).round(2)
  end

  def people_with_birthdays(start_date, end_date)
    start_month = start_date.month
    end_month = end_date.month
    if start_month == end_month
      people_with_birthdays = people.where('people.birthday_month = ?', start_month)
                              .where('people.birthday_day BETWEEN ? AND ?', start_date.day, end_date.day)
    else
      people_with_birthdays = people.where("(people.birthday_month = ? AND people.birthday_day >= ?)
                                           OR (people.birthday_month = ? AND people.birthday_day <= ?)",
                                           start_month, start_date.day, end_month, end_date.day)

    end
    people_with_birthdays.order('people.birthday_month, people.birthday_day').merge(contacts.active)
  end

  def people_with_anniversaries(start_date, end_date)
    start_month = start_date.month
    end_month = end_date.month
    if start_month == end_month
      people_with_birthdays = people.where('people.anniversary_month = ?', start_month)
                              .where('people.anniversary_day BETWEEN ? AND ?', start_date.day, end_date.day)
    else
      people_with_birthdays = people.where("(people.anniversary_month = ? AND people.anniversary_day >= ?)
                                           OR (people.anniversary_month = ? AND people.anniversary_day <= ?)",
                                           start_month, start_date.day, end_month, end_date.day)
    end
    people_with_birthdays.order('people.anniversary_month, people.anniversary_day').merge(contacts.active)
  end

  def top_50_percent
    return @top_50_percent if @top_50_percent
    financial_partners_count = contacts.where('pledge_amount > 0').count
    @top_50_percent = contacts.where('pledge_amount > 0')
                      .order('(pledge_amount::numeric / (pledge_frequency::numeric)) desc')
                      .limit(financial_partners_count / 2)
  end

  def bottom_50_percent
    return @button if @bottom_50_percent
    @bottom_50_percent = contacts.where('pledge_amount > 0')
                         .order('(pledge_amount::numeric / (pledge_frequency::numeric))')
                         .limit(contacts.where('pledge_amount > 0').count / 2)
  end

  def no_activity_since(date, contacts_scope = nil, activity_type = nil)
    no_activity_since = []
    contacts_scope ||= contacts
    contacts_scope.includes(people: [:primary_phone_number, :primary_email_address]).each do |contact|
      activities = contact.tasks.where('completed_at > ?', date)
      activities = activities.where('activity_type = ?', activity_type) if activity_type.present?
      no_activity_since << contact if activities.empty?
    end
    no_activity_since
  end

  def merge_contacts
    merged_contacts = []

    ordered_contacts = contacts.includes(:addresses, :donor_accounts).order('contacts.created_at')
    ordered_contacts.each do |contact|
      next if merged_contacts.include?(contact)

      other_contacts = ordered_contacts.select do |c|
        c.name == contact.name &&
        c.id != contact.id &&
        (c.donor_accounts.first == contact.donor_accounts.first ||
         c.addresses.find { |a| contact.addresses.find { |ca| ca.equal_to? a } })
      end
      next unless other_contacts.present?
      other_contacts.each do |other_contact|
        contact.merge(other_contact)
        merged_contacts << other_contact
      end
    end

    contacts.reload
    contacts.map(&:merge_people)
    contacts.map(&:merge_addresses)
  end

  # Download all donations / info for all accounts associated with this list
  def self.update_linked_org_accounts
    AccountList.joins(:organization_accounts).where('locked_at is null').order('last_download asc')
      .each do |al|
      al.async(:import_data)
    end
  end

  def self.find_or_create_from_profile(profile, org_account)
    user = org_account.user
    organization = org_account.organization
    designation_numbers = profile.designation_accounts.map(&:designation_number)
    # look for an existing account list with the same designation numbers in it
    account_list = AccountList.find_with_designation_numbers(designation_numbers, organization)
    # otherwise create a new account list for this profile
    account_list ||= AccountList.where(name: profile.name, creator_id: user.id).first_or_create!

    # Add designation accounts to account_list
    profile.designation_accounts.each do |da|
      account_list.designation_accounts << da unless account_list.designation_accounts.include?(da)
    end

    # Add user to account list
    account_list.users << user unless account_list.users.include?(user)
    profile.update_attributes(account_list_id: account_list.id)

    account_list
  end

  def merge(other)
    AccountList.transaction do
      # Intentionally don't copy over notification_preferences since they may conflict between accounts
      [:activities, :appeals, :company_partnerships, :contacts, :designation_profiles,
       :google_integrations, :help_requests, :imports, :messages, :recurring_recommendation_results
      ].each { |has_many| other.send(has_many).update_all(account_list_id: id) }

      [:mail_chimp_account, :prayer_letters_account].each do |has_one|
        next unless send(has_one).nil? && other.send(has_one).present?
        other.send(has_one).update(account_list_id: id)
      end

      [:designation_accounts, :companies].each do |copy_if_missing|
        other.send(copy_if_missing).each do |item|
          send(copy_if_missing) << item unless send(copy_if_missing).include?(item)
        end
      end

      other.users.each do |user|
        next if users.include?(user)
        users << user
        user.update(preferences: nil)
      end

      other.reload
      other.destroy

      save(validate: false)
    end
  end

  # This method checks all of your donors and tries to intelligently determin which partners are regular givers
  # based on thier giving history.
  def update_partner_statuses
    contacts.where(status: nil).joins(:donor_accounts).each do |contact|
      # If they have a donor account id, they are at least a special donor
      # If they have given the same amount for the past 3 months, we'll assume they are
      # a monthly donor.
      gifts = donations.where(donor_account_id: contact.donor_account_ids,
                              designation_account_id: designation_account_ids)
              .order('donation_date desc')
      latest_donation = gifts[0]

      next unless latest_donation

      pledge_frequency = contact.pledge_frequency
      pledge_amount = contact.pledge_amount

      if latest_donation.donation_date.to_time > 2.months.ago && latest_donation.channel == 'Recurring'
        status = 'Partner - Financial'
        pledge_frequency = 1 unless contact.pledge_frequency
        pledge_amount = latest_donation.amount unless contact.pledge_amount.to_i > 0
      else
        status = 'Partner - Special'
      end

      # Re-query the contact to make it not read-only from the join
      # (there are other ways to handle that, but this one was easy)
      Contact.find(contact.id).update_attributes(status: status, pledge_frequency: pledge_frequency, pledge_amount: pledge_amount)
    end
  end

  def all_contacts
    @all_contacts ||= contacts.order('contacts.name').select(['contacts.id', 'contacts.name'])
  end

  def cache_key
    super + total_pledges.to_s
  end

  def update_geocodes
    return if Redis.current.get("geocodes:#{id}")
    Redis.current.set("geocodes:#{id}", true)

    contacts.where(timezone: nil).find_each(&:set_timezone)
  end

  def async_send_chalkline_list
    # Since AccountList normally uses the lower priority :import queue use the :default queue for the
    # email to Chalkline which the user would expect to see soon after their clicking the button to send it.
    Sidekiq::Client.enqueue_to(:default, self.class, id, :send_chalkline_mailing_list)
  end

  def send_chalkline_mailing_list
    ChalklineMailer.mailing_list(self).deliver
  end

  def physical_newsletter_csv
    newsletter_contacts = ContactFilter.new(newsletter: 'address').filter(contacts)
    views = ActionView::Base.new('app/views', {}, ActionController::Base.new)
    views.render(file: 'contacts/index.csv.erb', locals: { contacts: newsletter_contacts })
  end

  def users_combined_name
    user1, user2 = users.order('created_at').limit(2).to_a[0..1]
    return name unless user1
    return "#{user1.first_name} #{user1.last_name}".strip unless user2

    if user2.last_name == user1.last_name
      "#{user1.first_name} and #{user2.first_name} #{user1.last_name}".strip
    else
      "#{user1.first_name} #{user1.last_name} and #{user2.first_name} #{user2.last_name}".strip
    end
  end

  def user_emails_with_names
    emails_with_nils = users.map do |user|
      next unless user.email
      address = Mail::Address.new user.email.email
      address.display_name = (user.first_name.to_s + ' ' + user.last_name.to_s).strip
      address.format
    end
    emails_with_nils.compact
  end

  def queue_sync_with_google_contacts
    return if google_integrations.where(contacts_integration: true).empty?
    return if organization_accounts.any?(&:downloading)
    return if imports.any?(&:importing)
    lower_retry_async(:sync_with_google_contacts)
  end

  def organization_accounts
    users.map(&:organization_accounts).flatten.uniq
  end

  def in_hand_percent
    (received_pledges * 100 / monthly_goal).round(1)
  end

  def pledged_percent
    (total_pledges * 100 / monthly_goal).round(1)
  end

  private

  def sync_with_google_contacts
    google_integrations.where(contacts_integration: true).find_each { |g_i| g_i.sync_data('contacts') }
  end

  def import_data
    organization_accounts.reject(&:disable_downloads).each(&:import_all_data)
    send_account_notifications
    queue_sync_with_google_contacts
  end

  # trigger any notifications for this account list
  def send_account_notifications
    notifications = NotificationType.check_all(self)

    notifications_to_email = {}

    # Check preferences for what to do with each notification type
    NotificationType.types.each do |notification_type_string|
      notification_type = notification_type_string.constantize.first

      next unless notifications[notification_type_string].present?
      actions = notification_preferences.find_by_notification_type_id(notification_type.id).try(:actions) ||
                NotificationPreference.default_actions

      # Collect any emails that need sent
      if actions.include?('email')
        notifications_to_email[notification_type] = notifications[notification_type_string]
      end

      next unless actions.include?('task')
      # Create a task for each notification
      notifications[notification_type_string].each do |notification|
        notification_type.create_task(self, notification)
      end
    end

    # Send email if necessary
    if notifications_to_email.present?
      NotificationMailer.notify(self, notifications_to_email).deliver
    end
  end

  def subscribe_tester_to_mailchimp
    return unless changes.keys.include?('settings') &&
                  changes['settings'][0]['tester'] != changes['settings'][1]['tester']

    if changes['settings'][1]['tester']
      async_to_queue(:default, :mc_subscribe_users, 'Testers')
    else
      async_to_queue(:default, :mc_unsubscribe_users, 'Testers')
    end
  end

  def subscribe_owners_to_mailchimp
    return unless changes.keys.include?('settings') &&
                  changes['settings'][0]['owner'] != changes['settings'][1]['owner']

    if changes['settings'][1]['owner']
      async_to_queue(:default, :mc_subscribe_users, 'Owners')
    else
      async_to_queue(:default, :mc_unsubscribe_users, 'Owners')
    end
  end

  def mc_subscribe_users(group)
    gb = Gibbon.new(ENV.fetch('MAILCHIMP_KEY'))
    users.each do |u|
      next unless u.email
      vars = { EMAIL: u.email.email, FNAME: u.first_name, LNAME: u.last_name,
               GROUPINGS: [{ id: ENV.fetch('MAILCHIMP_GROUPING_ID'), groups: group }] }
      gb.list_subscribe(id: ENV.fetch('MAILCHIMP_LIST'), email_address: vars[:EMAIL], update_existing: true,
                        double_optin: false, merge_vars: vars, send_welcome: false, replace_interests: false)
    end
  end

  def mc_unsubscribe_users(group)
    gb = Gibbon.new(ENV.fetch('MAILCHIMP_KEY'))
    users.each do |u|
      next if u.email.blank?
      # subtract this group from the list of groups this email is subscribed to
      result = gb.list_member_info(id: ENV.fetch('MAILCHIMP_LIST'), email_address: [u.email.email])
      next unless result['success'] > 0
      result['data'].each do |row|
        next unless row['email'] && row['merges']
        grouping = row['merges']['GROUPINGS'].detect { |g| g['id'] == ENV.fetch('MAILCHIMP_GROUPING_ID') }
        next unless grouping
        groups = grouping['groups'].split(', ')
        groups -= [group]
        vars = { GROUPINGS: [{ id: ENV.fetch('MAILCHIMP_GROUPING_ID'), groups: groups.join(', ') }] }
        gb.list_update_member(id: ENV.fetch('MAILCHIMP_LIST'), email_address: row['email'], merge_vars: vars,
                              replace_interests: true)
      end
    end
  end
end
