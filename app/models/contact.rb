class Contact < ApplicationRecord
  include AddressMethods
  acts_as_taggable
  include TagsEagerLoading
  extend ApplicationHelper

  # Track status and pledge details at most once per day in separate table
  has_attributes_history for: [:status, :pledge_amount, :pledge_frequency,
                               :pledge_received, :pledge_start_date],
                         with_model: PartnerStatusLog

  # Also track notes at most once per day in separate table
  has_attributes_history for: [:notes], with_model: ContactNotesLog

  has_many :contact_donor_accounts, dependent: :delete_all, inverse_of: :contact
  has_many :donor_accounts, through: :contact_donor_accounts, inverse_of: :contacts
  belongs_to :account_list
  has_many :contact_people, dependent: :destroy
  has_many :people, through: :contact_people
  has_one :primary_contact_person, -> { where(primary: true) }, class_name: 'ContactPerson', dependent: :destroy
  has_one :primary_person, through: :primary_contact_person, source: :person, autosave: true
  has_one :spouse_contact_person, -> { where(primary: [false, nil]) }, class_name: 'ContactPerson', dependent: :destroy
  has_one :spouse, through: :spouse_contact_person, source: :person, autosave: true
  has_many :contact_referrals_to_me, foreign_key: :referred_to_id, class_name: 'ContactReferral', dependent: :delete_all
  has_many :contact_referrals_by_me, foreign_key: :referred_by_id, class_name: 'ContactReferral', dependent: :delete_all
  has_many :contacts_that_referred_me, through: :contact_referrals_to_me, source: :referred_by
  has_many :contacts_referred_by_me, through: :contact_referrals_by_me, source: :referred_to
  has_many :activity_contacts, dependent: :destroy
  has_many :activities, through: :activity_contacts
  has_many :tasks, through: :activity_contacts, source: :task
  has_many :notifications, inverse_of: :contact, dependent: :destroy
  has_many :messages
  has_many :appeal_contacts
  has_many :appeals, through: :appeal_contacts
  has_many :excluded_appeal_contacts, class_name: 'Appeal::ExcludedAppealContact', dependent: :delete_all
  has_many :pledges

  serialize :prayer_letters_params, Hash
  serialize :suggested_changes, Hash

  scope :people, -> { where('donor_accounts.master_company_id is null').includes(:donor_accounts).references('donor_accounts') }
  scope :companies, -> { where('donor_accounts.master_company_id is not null').includes(:donor_accounts).references('donor_accounts') }
  scope :with_person, -> (person) { includes(:people).where('people.id' => person.id) }
  scope :for_donor_account, -> (donor_account) { where('donor_accounts.id' => donor_account.id).includes(:donor_accounts).references('donor_accounts') }
  scope :for_account_list, -> (account_list) { where(account_list_id: account_list.id) }
  scope :financial_partners, -> { where(status: 'Partner - Financial') }
  scope :non_financial_partners, -> { where("status <> 'Partner - Financial' OR status is NULL") }

  scope :with_referrals, -> { joins(:contact_referrals_by_me).uniq }
  scope :active, -> { where(active_conditions) }
  scope :inactive, -> { where(inactive_conditions) }
  scope :active_or_unassigned, -> { where(active_or_unassigned_conditions) }
  scope :late_by, lambda { |min_days, max_days = 100.years|
    financial_partners.where(late_at: (max_days || 100.years).ago..min_days.ago)
  }
  scope :created_between, -> (start_date, end_date) { where('contacts.created_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone) }

  PERMITTED_ATTRIBUTES = [
    :account_list_id,
    :church_name,
    :created_at,
    :direct_deposit,
    :envelope_greeting,
    :full_name,
    :greeting,
    :likely_to_give,
    :locale,
    :magazine,
    :name,
    :next_ask,
    :no_appeals,
    :no_gift_aid,
    :not_duplicated_with,
    :notes,
    :overwrite,
    :pledge_amount,
    :pledge_currency,
    :pledge_frequency,
    :pledge_received,
    :pledge_start_date,
    :primary_person_id,
    :send_newsletter,
    :status,
    :status_valid,
    :tag_list,
    :timezone,
    :updated_at,
    :updated_in_db_at,
    :uuid,
    :website,
    {
      addresses_attributes: [
        :_destroy,
        :city,
        :country,
        :historic,
        :id,
        :location,
        :master_address_id,
        :metro_area,
        :overwrite,
        :postal_code,
        :primary_mailing_address,
        :region,
        :remote_id,
        :state,
        :street,
        :source,
        :user_changed,
        :valid_values
      ],
      contact_referrals_to_me_attributes: [
        :_destroy,
        :id,
        :overwrite,
        :referred_by_id
      ],
      contact_referrals_by_me_attributes: [
        :_destroy,
        :id,
        :overwrite,
        :referred_to_id
      ],
      donor_accounts_attributes: [
        :_destroy,
        :account_number,
        :id,
        :organization_id,
        :overwrite
      ],
      people_attributes: Person::PERMITTED_ATTRIBUTES + [:overwrite],
      contacts_referred_by_me_attributes: [
        :_destroy,
        :account_list_id,
        :id,
        :name,
        :notes,
        :overwrite,
        :primary_address_city,
        :primary_address_postal_code,
        :primary_address_state,
        :primary_address_street,
        :primary_person_email,
        :primary_person_first_name,
        :primary_person_last_name,
        :primary_person_phone,
        :spouse_email,
        :spouse_first_name,
        :spouse_last_name,
        :spouse_phone,
        :uuid
      ],
      tag_list: []
    }
  ].freeze

  MERGE_COPY_ATTRIBUTES = [
    :name, :pledge_amount, :status, :full_name, :greeting, :envelope_greeting, :website, :pledge_frequency,
    :pledge_start_date, :next_ask, :likely_to_give, :church_name, :no_appeals, :pls_id,
    :direct_deposit, :magazine, :pledge_received, :timezone, :last_activity, :last_appointment, :last_letter,
    :last_phone_call, :last_pre_call, :last_thank, :prayer_letters_id, :last_donation_date, :first_donation_date, :tnt_id
  ].freeze

  validates :account_list_id, presence: true
  validates :addresses, single_primary: { primary_field: :primary_mailing_address }, if: :user_changed
  validates :name, presence: true
  validates :pledge_amount, numericality: true, allow_nil: true

  accepts_nested_attributes_for :people, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :donor_accounts, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :contact_people, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :contact_referrals_to_me, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :contacts_referred_by_me, reject_if: :all_blank, allow_destroy: false

  before_save :set_notes_saved_at, :update_late_at, :check_state_for_mail_chimp_sync
  after_commit :sync_with_mail_chimp, :sync_with_letter_services, :sync_with_google_contacts
  after_create :create_people_from_contact, if: :prefill_attributes_on_create
  before_destroy :delete_from_letter_services, :delete_people
  LETTER_SERVICES = [:pls, :prayer_letters].freeze

  # loaded_donations is used by Contact::DonationsEagerLoader
  attr_accessor :user_changed, :loaded_donations, :prefill_attributes_on_create

  # Don't change these willy-nilly, they break the mobile app
  ASSIGNABLE_STATUSES = [
    'Never Contacted', 'Ask in Future', 'Cultivate Relationship', 'Contact for Appointment',
    'Appointment Scheduled', 'Call for Decision', 'Partner - Financial', 'Partner - Special',
    'Partner - Pray', 'Not Interested', 'Unresponsive', 'Never Ask', 'Research Abandoned',
    'Expired Referral'
  ].freeze
  assignable_values_for :status, allow_blank: true do
    ASSIGNABLE_STATUSES
  end

  INACTIVE_STATUSES = [
    'Not Interested', 'Unresponsive', 'Never Ask', 'Research Abandoned',
    'Expired Referral'
  ].freeze
  ACTIVE_STATUSES = ASSIGNABLE_STATUSES - INACTIVE_STATUSES

  IN_PROGRESS_STATUSES = [
    'Never Contacted', 'Ask in Future', 'Contact for Appointment',
    'Appointment Scheduled',
    'Call for Decision'
  ].freeze

  def status=(val)
    # handle deprecated values
    self[:status] = case val
                    when 'Call for Appointment'
                      'Contact for Appointment'
                    else
                      val
                    end
  end

  ASSIGNABLE_LIKELY_TO_GIVE = ['Least Likely', 'Likely', 'Most Likely'].freeze

  assignable_values_for :likely_to_give, allow_blank: true do
    ASSIGNABLE_LIKELY_TO_GIVE
  end

  ASSIGNABLE_SEND_NEWSLETTER = %w(Physical Email Both).freeze
  assignable_values_for :send_newsletter, allow_blank: true do
    ASSIGNABLE_SEND_NEWSLETTER
  end

  delegate :first_name, :last_name, :phone, :email, to: :primary_or_first_person
  delegate :street, :city, :csv_street, :state, :postal_code, to: :mailing_address

  # These delegations exist to facilitate creating referrals (as new contact records) with nested attributes
  delegate :street, :city, :state, :postal_code, to: :primary_address, prefix: :primary_address, allow_nil: true
  delegate 'street=', 'city=', 'state=', 'postal_code=', to: :find_or_build_primary_address, prefix: :primary_address

  delegate :first_name, :last_name, :phone, :email, to: :primary_person, prefix: :primary_person, allow_nil: true
  delegate 'first_name=', 'last_name=', 'phone=', 'email=', to: :find_or_build_primary_person, prefix: :primary_person

  delegate :first_name, :last_name, :phone, :email, to: :spouse, prefix: :spouse, allow_nil: true
  delegate 'first_name=', 'last_name=', 'phone=', 'email=', to: :find_or_build_spouse, prefix: :spouse

  def to_s
    name
  end

  def add_person(person, donor_account = nil)
    # Nothing to do if this person is already on the contact
    new_person = people.find_by(master_person_id: person.master_person_id)

    unless new_person
      new_person = Person.clone(person)
      people << new_person
      donor_account.people << new_person if donor_account
    end

    new_person
  end

  def add_to_notes(new_note)
    return if notes.to_s.include?(new_note.to_s)
    self.notes = if notes.present?
                   "#{notes} \n \n#{new_note}"
                 else
                   new_note
                 end
    save
  end

  def mailing_address
    # Use .reject(&:historic) and not .where.not(historic: true) because the
    # CSV import uses mailing_address for checking the addresses for contacts
    # before saving them to the database.
    @mailing_address ||= primary_address ||
                         addresses.reject(&:historic).first || Address.new
  end

  def reload_mailing_address
    @mailing_address = nil
    mailing_address.reload unless mailing_address.new_record?
    mailing_address
  end

  def hide
    update_attributes(status: 'Never Ask')
  end

  def active?
    !Contact.inactive_statuses.include?(status)
  end

  def late_by?(min_days, max_days = nil)
    return false unless status == 'Partner - Financial' && pledge_frequency.present? && late_at
    min_late_date = Date.today - min_days
    max_late_date = max_days ? Date.today - max_days : Date.new(1951, 1, 1)
    late_at > max_late_date && late_at < min_late_date
  end

  def update_late_at
    initial_date = last_donation_date || pledge_start_date
    return unless status == 'Partner - Financial' && pledge_frequency.present? && initial_date.present?

    self.late_at = case
                   when pledge_frequency >= 1.0
                     initial_date + pledge_frequency.to_i.months
                   when pledge_frequency >= 0.4
                     initial_date + 2.weeks
                   else
                     initial_date + 1.week
                   end
  end

  def self.active_conditions
    "status IN('#{active_statuses.join("','")}') or status is null"
  end

  def self.inactive_conditions
    "status IN('#{inactive_statuses.join("','")}')"
  end

  def self.active_or_unassigned_conditions
    active_or_unassigned_statuses = active_statuses + ['']
    "status IN('#{active_or_unassigned_statuses.join("','")}')"
  end

  def self.active_statuses
    ACTIVE_STATUSES
  end

  def self.inactive_statuses
    INACTIVE_STATUSES
  end

  def self.create_from_donor_account(donor_account, account_list)
    contact = account_list.contacts.new(name: donor_account.name,
                                        locale: donor_account.organization&.locale)
    contact.addresses_attributes = donor_account.addresses_attributes
    contact.addresses.each { |a| a.source_donor_account = donor_account }
    contact.save!
    contact.donor_accounts << donor_account
    contact
  end

  def primary_or_first_person
    @primary_or_first_person ||= primary_person
    return @primary_or_first_person if @primary_or_first_person
    return Person.new if people.blank?

    @primary_or_first_person = if people.count == 1
                                 people.first
                               else
                                 people.alive.find_by(gender: 'male') || people.alive.order('created_at').first
                               end
    if @primary_or_first_person && @primary_or_first_person.new_record? && !new_record?
      self.primary_person_id = @primary_or_first_person.id
    end
    @primary_or_first_person || Person.new
  end

  def clear_primary_person
    @primary_or_first_person = nil
    self.primary_person_id = nil
  end

  def primary_person_id
    primary_or_first_person.id
  end

  def primary_person_id=(person_id)
    if person_id
      cp = contact_people.find_by(person_id: person_id)
      cp&.update_attributes(primary: true)
    end
    person_id
  end

  def greeting
    self[:greeting].present? ? self[:greeting] : generated_greeting
  end

  def generated_greeting
    return name if siebel_organization?
    return first_name if spouse.try(:deceased)
    return spouse_first_name if primary_or_first_person.deceased && spouse
    [first_name, spouse_first_name].compact.join(" #{_('and')} ")
  end

  def envelope_greeting
    self[:envelope_greeting].present? ? self[:envelope_greeting] : generated_envelope_greeting
  end

  def generated_envelope_greeting
    return name if siebel_organization?
    working_name = name.to_s.strip
    working_name.chomp!(',') if working_name.ends_with? ','
    return working_name unless working_name.include? ','
    last_name = working_name.split(',')[0].strip
    first_names = working_name.split(',')[1].strip
    return first_names + ' ' + last_name unless first_names =~ /\((\w|\W)*\)/
    first_names = first_names.split(/ & | #{_('and')} /)
    if first_names[0] =~ /\((\w|\W)*\)/
      first_names.each { |first_name| first_name.sub!(/\((\w|\W)*\)/, '') }
      first_names.each(&:strip!)
      env_greeting = if first_names[1].present?
                       "#{first_names[0]} #{_('and')} #{first_names[1]} #{last_name}"
                     else
                       "#{first_names[0]} #{last_name}"
                     end
      return env_greeting
    end
    if donor_accounts.where(name: name).any?
      # Contacts from the donor system usually have nicknames, not a different
      # last name in paren, i.e. "Doe, John and Janet (Jane)" not "Doe, John and Janet (Smith)"
      nickname_stripped = first_names[1].gsub!(/\(.*?\)/, '').gsub(/\s\s+/, ' ').strip
      return "#{first_names[0]} #{_('and')} #{nickname_stripped} #{last_name}"
    end
    first_names[1].delete!('()')
    "#{first_names[0]} #{last_name} #{_('and')} #{first_names[1]}"
  end

  def siebel_organization?
    last_name == 'of the Ministry'
  end

  def update_donation_totals(donation)
    self.first_donation_date = donation.donation_date if first_donation_date.nil? || donation.donation_date < first_donation_date
    self.last_donation_date = donation.donation_date if last_donation_date.nil? || donation.donation_date > last_donation_date
    self.total_donations = total_donations.to_f + donation.amount
    save(validate: false)
  end

  def update_all_donation_totals
    update(total_donations: total_donations_query)
  end

  def total_donations_query
    @total_donations_query ||= donations.sum(:amount)
  end

  def monthly_pledge
    amount    = pledge_amount_for_monthly_pledge_calculation
    frequency = pledge_frequency_for_monthly_pledge_calculation

    (amount / frequency).round(2)
  end

  def send_email_letter?
    %w(Email Both).include?(send_newsletter)
  end

  def send_physical_letter?
    %w(Physical Both).include?(send_newsletter)
  end

  def pledge_currency
    self[:pledge_currency].present? ? self[:pledge_currency] : account_list.try(:default_currency)
  end

  def pledge_currency_symbol
    cldr_currency = TwitterCldr::Shared::Currencies.for_code(pledge_currency.upcase)
    cldr_currency.present? ? cldr_currency[:symbol] : pledge_currency
  end

  def confirmed_non_duplicate_of?(other)
    not_duplicated_with.to_s.split(',').include?(other.id.to_s) ||
      other.not_duplicated_with.to_s.split(',').include?(id.to_s)
  end

  def mark_not_duplicate_of!(other)
    not_duplicated_with_set = not_duplicated_with.to_s.split(',').to_set
    not_duplicated_with_set << other.id.to_s
    update_column(:not_duplicated_with, not_duplicated_with_set.to_a.join(','))
  end

  def donor_accounts_attributes=(attribute_collection)
    attribute_collection = Hash[(0...attribute_collection.size).zip attribute_collection] if attribute_collection.is_a?(Array)
    attribute_collection = attribute_collection.with_indifferent_access.values
    attribute_collection.each do |attrs|
      if attrs[:id].present? && (attrs[:account_number].blank? || attrs[:_destroy] == '1')
        ContactDonorAccount.where(donor_account_id: attrs[:id], contact_id: id).destroy_all
      elsif attrs[:account_number].blank?
        next
      elsif donor_account = DonorAccount.find_by(account_number: attrs[:account_number], organization_id: attrs[:organization_id])
        contact_donor_accounts.new(donor_account: donor_account) unless donor_account.contacts.include?(self)
      else
        assign_nested_attributes_for_collection_association(:donor_accounts, [attrs])
      end
    end
  end

  def deceased
    people.all?(&:deceased)
  end

  def deceased?
    deceased
  end

  def self.pledge_frequencies
    {
      0.23076923076923.to_d => _('Weekly'),
      0.46153846153846.to_d => _('Every 2 Weeks'),
      1.0.to_d => _('Monthly'),
      2.0.to_d => _('Every 2 Months'),
      3.0.to_d => _('Quarterly'),
      4.0.to_d => _('Every 4 Months'),
      6.0.to_d => _('Every 6 Months'),
      12.0.to_d => _('Annual'),
      24.0.to_d => _('Every 2 Years')
    }
  end

  def merge(other)
    ContactMerge.new(self, other).merge
  end

  def merge_people
    # Merge people that have the same name
    merged_people = []

    people.reload.each do |person|
      next if merged_people.include?(person)

      other_people = people.select do |p|
        p.first_name.to_s.strip.casecmp(person.first_name.to_s.strip.downcase).zero? &&
          p.last_name.to_s.strip.casecmp(person.last_name.to_s.strip.downcase).zero? &&
          p.id != person.id
      end
      next unless other_people
      other_people.each do |other_person|
        person.merge(other_person)
        merged_people << other_person
      end
    end
    people.reload
    people.map(&:merge_phone_numbers)
  end

  def merge_donor_accounts
    # Merge donor accounts that have the same number
    donor_accounts.reload.each do |account|
      other = donor_accounts.find do |da|
        da.id != account.id &&
          da.account_number == account.account_number
      end
      next unless other
      account.merge(other)
      merge_donor_accounts
      return
    end
  end

  def update_uncompleted_tasks_count
    self.uncompleted_tasks_count = tasks.uncompleted.count
    save(validate: false)
  end

  def find_timezone
    return unless primary_or_first_address
    primary_or_first_address.master_address.find_timezone
  rescue
  end

  def primary_or_first_address
    @primary_or_first_address ||=
      addresses.find(&:primary_mailing_address?) || addresses.first
  end

  def set_timezone
    timezone = find_timezone
    update_column(:timezone, find_timezone) unless timezone == self.timezone
  end

  def should_be_in_prayer_letters?
    send_physical_letter? && name.present? && envelope_greeting.present? &&
      mailing_address.present? && mailing_address.valid_mailing_address?
  end

  def donations
    Donation.where(donor_account: donor_accounts)
            .for_accounts(account_list.designation_accounts)
  end

  def last_six_donations
    donations.limit(6)
  end

  def last_donation
    donations.first
  end

  def last_monthly_total(except_payment_method: nil)
    scoped_donations = donations
    scoped_donations = scoped_donations.where.not(payment_method: except_payment_method) if except_payment_method
    scoped_donations.where('donation_date >= ?',
                           last_donation_month_end.beginning_of_month).sum(:amount)
  end

  def prev_month_donation_date
    donations.where('donation_date <= ?', (last_donation_month_end << 1).end_of_month)
             .pluck(:donation_date).first
  end

  def monthly_avg_current(except_payment_method: nil)
    monthly_avg_over_range(current_pledge_interval_start, last_donation_month_end, except_payment_method: except_payment_method)
  end

  def monthly_avg_with_prev_gift(except_payment_method: nil)
    monthly_avg_over_range(prev_donation_month_start, last_donation_month_end, except_payment_method: except_payment_method)
  end

  def monthly_avg_from(date, except_payment_method: nil)
    return unless date
    monthly_avg_over_range(start_of_pledge_interval(date), last_donation_month_end, except_payment_method: except_payment_method)
  end

  def months_from_prev_to_last_donation
    return unless last_donation && prev_month_donation_date
    month_diff(prev_month_donation_date, last_donation.donation_date)
  end

  def current_pledge_interval_donations
    interval_donations(current_pledge_interval_start, last_donation_month_end)
  end

  def current_pledge_interval_start
    prev_months_to_include = [(pledge_frequency || 1) - 1, 0].max
    (last_donation_month_end << prev_months_to_include).beginning_of_month
  end

  def self.bulk_update_options(current_account_list)
    options = {}
    options['likely_to_give'] = ASSIGNABLE_LIKELY_TO_GIVE
    options['status'] = ASSIGNABLE_STATUSES
    options['send_newsletter'] = ASSIGNABLE_SEND_NEWSLETTER
    options['pledge_received'] = %w(Yes No)
    options['pledge_currency'] = currency_select(current_account_list)
    options
  end

  def amount_with_gift_aid(amount)
    amount ||= 0

    (amount * gift_aid_coefficient).round(2)
  end

  def pledge_amount=(pledge_amount)
    pledge_amount = if pledge_amount.to_s.index(',').to_i < pledge_amount.to_s.index('.').to_i
                      pledge_amount.to_s.delete(',')
                    else
                      pledge_amount.to_s.delete('.')
                    end
    self[:pledge_amount] = pledge_amount.blank? ? nil : pledge_amount.to_f
  end

  def mail_chimp_open_rate
    return nil unless email
    mail_chimp_member_request
  end

  def create_people_from_contact
    name_parts = name.split(',')
    if name_parts.length > 1
      last_name = name_parts[0]
      name_parts[1].split(/\sand\s|\s&\s/).map { |i| i.strip if i.strip != '' }.uniq.compact.map do |first_name|
        people << Person.new(first_name: first_name, last_name: last_name)
      end
    else
      people << Person.new(first_name: name)
    end
    save
  end

  private

  def mail_chimp_member_request
    return unless mail_chimp_account&.primary_list_id

    gibbon_wrapper = MailChimp::GibbonWrapper.new(mail_chimp_account)
    gibbon_wrapper.gibbon_list_object(mail_chimp_account.primary_list_id)
                  .members(email_hash(email)).retrieve['stats']['avg_open_rate']
  rescue Gibbon::MailChimpError => error
    return nil if error.title =~ /Resource Not Found/
    raise error
  end

  def mail_chimp_account
    account_list.mail_chimp_account
  end

  def email_hash(email)
    Digest::MD5.hexdigest(email.email.downcase)
  end

  def gift_aid_coefficient
    (1 + (gift_aid_percentage.to_f / 100))
  end

  def gift_aid_percentage
    return 0 if no_gift_aid?

    donor_accounts.first.try(:organization).try(:gift_aid_percentage) || 0
  end

  def monthly_avg_over_range(start_date, end_date, except_payment_method: nil)
    scoped_donations = interval_donations(start_date, end_date)
    scoped_donations = scoped_donations.where.not(payment_method: except_payment_method) if except_payment_method
    scoped_donations.sum(:amount) / months_in_range(start_date, end_date)
  end

  def interval_donations(start_date, end_date)
    donations
      .where('donation_date >= ?', start_date)
      .where('donation_date <= ?', end_date)
  end

  def last_donation_month_end
    @last_donation_month_end ||=
      if last_donation_date && month_diff(last_donation_date, Date.today) > 0
        Date.today.prev_month.end_of_month
      else
        Date.today.end_of_month
      end
  end

  def prev_donation_month_start
    @prev_donation_month_start ||=
      start_of_pledge_interval([first_donation_date, Date.today << 12,
                                prev_month_donation_date].compact.max)
  end

  def start_of_pledge_interval(date)
    months_in_range_mod_freq = months_in_range(date, last_donation_month_end) % pledge_frequency
    months_to_subtract = months_in_range_mod_freq == 0 ? 0 : pledge_frequency - months_in_range_mod_freq
    (date << months_to_subtract).beginning_of_month
  end

  def month_diff(start_date, end_date)
    (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month)
  end

  def months_in_range(start_date, end_date)
    month_diff(start_date, end_date) + 1
  end

  def delete_people
    people.each do |person|
      # If this person isn't linked to any other contact, delete them
      next if account_list.people.where("people.id = #{person.id} AND contact_people.contact_id <> #{id}").any?
      person.destroy
    end

    contact_people.destroy_all
  end

  def set_notes_saved_at
    self.notes_saved_at = DateTime.now if changed.include?('notes')
  end

  def check_state_for_mail_chimp_sync
    @sync_mail_chimp = if relevant_nested_attribute_changed? || relevant_contact_attribute_changed?
                         true
                       else
                         false
                       end
    true
  end

  def relevant_contact_attribute_changed?
    (changed & %w(locale status tag_list send_newsletter)).present?
  end

  def relevant_nested_attribute_changed?
    people.any? do |person|
      person.primary_email_address&.email_changed? ||
        person.first_name_changed? ||
        person.last_name_changed?
    end
  end

  def sync_with_mail_chimp
    return unless @sync_mail_chimp && account_list.mail_chimp_account

    MailChimp::ExportContactsWorker.perform_async(
      account_list.mail_chimp_account.id, account_list.mail_chimp_account.primary_list_id, [id]
    )
  end

  def sync_with_google_contacts
    account_list.queue_sync_with_google_contacts
  end

  def sync_with_letter_services
    LETTER_SERVICES.each { |service| sync_with_letter_service(service) }
  end

  def delete_from_letter_services
    LETTER_SERVICES.each { |service| delete_from_letter_service(service) }
  end

  def sync_with_letter_service(service)
    return unless account_list && account_list.send("valid_#{service}_account")

    # in case an association change triggered this
    reload_mailing_address

    pl = account_list.send("#{service}_account")

    if should_be_in_prayer_letters?
      pl.add_or_update_contact(self)
    else
      delete_from_letter_service(service)
    end
  end

  def delete_from_letter_service(service)
    # If this contact was at prayerletters.com and no other contact on this list has the
    # same prayer_letters_id, remove this contact from prayerletters.com
    return if send("#{service}_id").blank?
    return unless account_list && account_list.send("valid_#{service}_account")
    return if account_list.contacts.where("#{service}_id" => send("#{service}_id")).where.not(id: id).present?

    account_list.send("#{service}_account").delete_contact(self)
  end

  def find_or_build_spouse
    @find_or_build_spouse ||= (spouse || build_spouse_contact_person.build_person)
  end

  def find_or_build_primary_person
    @find_or_build_primary_person ||= (primary_person || build_primary_contact_person.build_person)
  end

  def find_or_build_primary_address
    @find_or_build_primary_address ||= (primary_address || build_primary_address)
  end

  def pledge_amount_for_monthly_pledge_calculation
    if pledge_amount&.positive?
      pledge_amount.to_f
    else
      0
    end
  end

  def pledge_frequency_for_monthly_pledge_calculation
    if pledge_frequency&.positive?
      pledge_frequency
    else
      1 # default
    end
  end
end
