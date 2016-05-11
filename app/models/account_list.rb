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

  # Expire the uniqueness for AccountList import after 24 hours because the
  # uniqueness locks were staying around incorrectly and causing some people's
  # donor import to not go through.
  sidekiq_options retry: false, unique: true, unique_job_expiration: 24.hours

  store :settings, accessors: [:monthly_goal, :tester, :owner, :home_country, :ministry_country,
                               :currency, :salary_currency, :log_debug_info,
                               :salary_organization_id]

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  has_many :account_list_users, dependent: :destroy
  has_many :users, through: :account_list_users
  has_many :organization_accounts, through: :users
  has_many :organizations, -> { distinct }, through: :organization_accounts
  has_many :account_list_entries, dependent: :destroy
  has_many :designation_accounts, through: :account_list_entries
  has_many :designation_organizations, -> { distinct }, through: :designation_accounts,
                                                        source: :organization
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

  scope :with_linked_org_accounts, lambda {
    joins(:organization_accounts).where('locked_at is null').order('last_download asc')
  }

  def salary_organization_id=(val)
    settings[:salary_organization_id] = val
    settings[:salary_currency] = Organization.find(val).default_currency_code
  end

  def salary_organization_id
    settings[:salary_organization_id] || designation_organizations.first&.id ||
      organizations&.first&.id
  end

  def salary_currency
    return @salary_currency if @salary_currency
    @salary_currency = settings[:salary_currency]
    @salary_currency = Organization.find(salary_organization_id).default_currency_code if @salary_currency.blank?
    @salary_currency
  end

  def monthly_goal=(val)
    settings[:monthly_goal] = val.to_s.gsub(/[^\d\.]/, '').to_i if val
  end

  def monthly_goal
    settings[:monthly_goal].present? && settings[:monthly_goal].to_i > 0 ? settings[:monthly_goal].to_i : nil
  end

  def salary_currency_or_default
    salary_currency || default_currency
  end

  def default_currency
    return @default_currency if @default_currency
    @default_currency = settings[:currency] if settings[:currency].present?
    @default_currency ||= designation_profiles.try(:first).try(:organization).try(:default_currency_code)
    @default_currency = 'USD' if @default_currency.blank?
    @default_currency
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

  def currencies
    @currencies ||=
      (contacts.order(:pledge_currency).pluck('DISTINCT pledge_currency') +
       organizations.pluck(:default_currency_code) +
       [default_currency]).compact.uniq
  end

  def multi_currency?
    currencies.count > 1
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
    scope_donations_by_designations(
      Donation.where(donor_account_id: donor_account_ids)
    )
  end

  def scope_donations_by_designations(donations)
    if designation_account_ids.present?
      donations.where(designation_account_id: designation_account_ids)
    else
      donations
    end
  end

  def designation_profile(user)
    designation_profiles.where(user_id: user.id).last
  end

  def total_pledges
    @total_pledges ||= AccountList::PledgesTotal.new(self, contacts.financial_partners).total
  end

  def received_pledges
    @received_pledges ||= AccountList::PledgesTotal.new(self, contacts.financial_partners.where(pledge_received: true)).total
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
    people_with_birthdays.alive
                         .order('people.birthday_month, people.birthday_day').merge(contacts.active)
  end

  def contacts_with_anniversaries(start_date, end_date)
    start_month = start_date.month
    end_month = end_date.month

    contacts_with_anniversaries = active_contacts.includes(:people)

    if start_month == end_month
      contacts_with_anniversaries = contacts_with_anniversaries
                                    .where('people.anniversary_month = ?', start_month)
                                    .where('people.anniversary_day BETWEEN ? AND ?', start_date.day, end_date.day)
    else
      contacts_with_anniversaries = contacts_with_anniversaries
                                    .where("(people.anniversary_month = ? AND people.anniversary_day >= ?)
               OR (people.anniversary_month = ? AND people.anniversary_day <= ?)",
                                           start_month, start_date.day, end_month, end_date.day)
    end

    contacts_with_anniversaries
      .order('people.anniversary_month, people.anniversary_day')
      .reject { |contact| contact.people.where(deceased: true).any? }
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
    Contact::DupContactsMerge.new(contacts).merge_duplicates
  end

  # Download all donations / info for all accounts associated with this list
  def self.update_linked_org_accounts
    AsyncScheduler.schedule_over_24h(with_linked_org_accounts, :import_data)
  end

  def merge(other)
    AccountList::Merge.new(self, other).merge
  end

  # This method checks all of your donors and tries to intelligently determine
  # which partners are regular givers based on their giving history.
  def update_partner_statuses
    contacts.where(status: nil).joins(:donor_accounts).readonly(false).each do |contact|
      Contact::PartnerStatusGuesser.new(contact).assign_guessed_status
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
    newsletter_contacts = ContactFilter.new(newsletter: 'address').filter(contacts, self)
    views = ActionView::Base.new('app/views', {}, ActionController::Base.new)
    views.render(file: 'contacts/index.csv.erb',
                 locals: { contacts: newsletter_contacts,
                           current_account_list: self })
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
    return if imports.any?(&:importing) || mail_chimp_account.try(&:importing)
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

  # trigger any notifications for this account list
  def send_account_notifications
    AccountList::NotificationsSender.new(self).send_notifications
  end

  def import_data
    import_donations
    if fix_dup_balances
      # Import donations again if we fixed any dup balances
      import_donations
    end
    send_account_notifications
    queue_sync_with_google_contacts
  end

  private

  def sync_with_google_contacts
    # Find the Google integrations 1 by 1 so accounts with multiple integrations
    # can release memory associated with the sync.
    google_integrations.where(contacts_integration: true)
                       .find_each(batch_size: 1) { |g_i| g_i.sync_data('contacts') }
  end

  def import_donations
    organization_accounts.reject(&:disable_downloads).each(&:import_all_data)
  end

  def fix_dup_balances
    DesignationAccount::DupByBalanceFix.deactivate_dups(designation_accounts)
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
