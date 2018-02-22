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

class AccountList < ApplicationRecord
  include Async
  include Sidekiq::Worker

  # Expire the uniqueness for AccountList import after 24 hours because the
  # uniqueness locks were staying around incorrectly and causing some people's
  # donor import to not go through.
  sidekiq_options queue: :api_account_list, retry: false, unique: :until_executed, unique_job_expiration: 24.hours

  validates :name, presence: true
  validate :active_mpd_start_at_is_before_active_mpd_finish_at

  store :settings, accessors: [:monthly_goal, :tester, :owner, :home_country, :ministry_country,
                               :currency, :salary_currency, :log_debug_info,
                               :salary_organization_id]

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'

  has_many :account_list_entries, dependent: :destroy
  has_many :account_list_invites, dependent: :destroy
  has_many :account_list_users, dependent: :destroy
  has_many :account_list_coaches, dependent: :destroy
  has_many :active_contacts, -> { where(Contact.active_conditions) }, class_name: 'Contact'
  has_many :active_people, through: :active_contacts, source: :people, class_name: 'Person'
  has_many :activities, dependent: :destroy
  has_many :activity_tags, through: :activities, source: :base_tags
  has_many :addresses, through: :contacts
  has_many :appeals
  belongs_to :primary_appeal, class_name: 'Appeal'
  has_many :balances, through: :designation_accounts, source: :balances
  has_many :companies, through: :company_partnerships
  has_many :company_partnerships, dependent: :destroy
  has_many :contact_tags, through: :contacts, source: :base_tags
  has_many :contacts, dependent: :destroy
  has_many :designation_accounts, through: :account_list_entries
  has_many :designation_organizations, -> { distinct }, through: :designation_accounts,
                                                        source: :organization
  has_many :designation_profiles
  has_many :donor_accounts, through: :contacts
  has_many :google_integrations, dependent: :destroy
  has_many :help_requests
  has_many :imports, dependent: :destroy
  has_many :master_people, through: :people
  has_many :messages
  has_many :notification_preferences, dependent: :destroy, autosave: true
  has_many :notifications, through: :contacts
  has_many :organization_accounts, through: :users
  has_many :organizations, -> { distinct }, through: :organization_accounts
  has_many :people, through: :contacts
  has_many :pledges, dependent: :destroy
  has_many :tasks
  has_many :coaches, through: :account_list_coaches
  has_many :users, through: :account_list_users
  has_many :duplicate_record_pairs, dependent: :delete_all

  has_one :mail_chimp_account, dependent: :destroy
  has_one :prayer_letters_account, dependent: :destroy, autosave: true
  has_one :pls_account, dependent: :destroy, autosave: true

  accepts_nested_attributes_for :contacts, reject_if: :all_blank, allow_destroy: true

  scope :with_linked_org_accounts, lambda {
    joins(:organization_accounts).where('locked_at IS NULL').order('last_download ASC')
  }

  scope :has_users, -> (users) { joins(:account_list_users).where(account_list_users: { user: users }) }

  scope :readable_by, -> (user) { AccountList::ReadableFinder.new(user).relation }

  PERMITTED_ATTRIBUTES = [
    :created_at,
    :currency,
    :home_country,
    :monthly_goal,
    :name,
    :overwrite,
    :salary_organization,
    :tester,
    :primary_appeal_id,
    :active_mpd_start_at,
    :active_mpd_finish_at,
    :active_mpd_monthly_goal,
    :updated_at,
    :updated_in_db_at,
    :uuid
  ].freeze

  audited

  alias unsafe_destroy destroy
  def destroy
    raise "It's not safe to call #destroy on an AccountList record. Because the large amount of dependents " \
      'and callbacks causes it to take too long and to consume too much memory. See AccountList::Destroyer class instead.'
  end
  alias destroy! destroy

  def salary_organization=(value)
    value = Organization.where(uuid: value).limit(1).ids.first unless value.is_a?(Integer)
    self.salary_organization_id = value
  end

  def salary_organization_id=(value)
    settings[:salary_organization_id] = value if value.is_a?(Integer)
    settings[:salary_organization_id] ||= value.id
    settings[:salary_currency] = Organization.find(settings[:salary_organization_id]).default_currency_code
  end

  def salary_organization_id
    settings[:salary_organization_id] || designation_organizations.first&.id ||
      organizations&.first&.id
  end

  def salary_currency
    return @salary_currency unless @salary_currency.blank?

    @salary_currency ||= settings[:salary_currency] if settings[:salary_currency].present?
    @salary_currency ||= Organization.find(salary_organization_id).default_currency_code if salary_organization_id
    @salary_currency = 'USD' if @salary_currency.blank?

    @salary_currency
  end

  def monthly_goal=(val)
    settings[:monthly_goal] = val.to_s.gsub(/[^\d\.]/, '').to_i if val
  end

  def monthly_goal
    settings[:monthly_goal].present? && settings[:monthly_goal].to_i.positive? ? settings[:monthly_goal].to_i : nil
  end

  def salary_currency_or_default
    salary_currency || default_currency
  end

  def default_currency
    return @default_currency unless @default_currency.blank?

    @default_currency ||= settings[:currency] if settings[:currency].present?
    @default_currency ||= designation_profiles.try(:first).try(:organization).try(:default_currency_code)
    @default_currency = 'USD' if @default_currency.blank?

    @default_currency
  end

  def multiple_designations
    designation_accounts.length > 1 ? true : false
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

  def contact_locales
    @locales ||= contacts.pluck('DISTINCT locale')
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
    donations.where(designation_account_id: designation_account_ids)
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
                         .order('people.birthday_month, people.birthday_day')
                         .merge(contacts.active)
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

  def async_merge_contacts(since_time)
    QueueContactDupMergeBatchWorker.perform_async(id, since_time.to_i)
  end

  def merge(other)
    AccountList::Merge.new(self, other).merge
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
    ChalklineMailer.delay.mailing_list(self)
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

    google_integrations.where(contacts_integration: true).find_each do |google_integration|
      google_integration.queue_sync_data('contacts')
    end
  end

  def organization_accounts
    users.map(&:organization_accounts).flatten.uniq
  end

  def in_hand_percent
    return unless monthly_goal
    (received_pledges * 100 / monthly_goal).round(1)
  end

  def pledged_percent
    return unless monthly_goal
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

  def import_donations
    organization_accounts.reject(&:disable_downloads).each(&:import_all_data)
  end

  def fix_dup_balances
    DesignationAccount::DupByBalanceFix.deactivate_dups(designation_accounts)
  end

  def tester_or_owner_setting_changed?
    changes.keys.include?('settings') &&
      (changes['settings'][0]['tester'] != changes['settings'][1]['tester'] ||
       changes['settings'][0]['owner'] != changes['settings'][1]['owner'])
  end

  def active_mpd_start_at_is_before_active_mpd_finish_at
    return unless active_mpd_start_at && active_mpd_finish_at
    return unless active_mpd_start_at >= active_mpd_finish_at
    errors[:active_mpd_start_at] << 'is after or equal to active mpd finish at date'
  end
end
