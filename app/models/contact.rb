class Contact < ActiveRecord::Base
  include AddressMethods
  acts_as_taggable
  include TagsEagerLoading

  has_paper_trail on: [:destroy, :update],
                  meta: { related_object_type: 'AccountList',
                          related_object_id: :account_list_id }

  has_many :contact_donor_accounts, dependent: :destroy, inverse_of: :contact
  has_many :donor_accounts, through: :contact_donor_accounts, inverse_of: :contacts
  belongs_to :account_list
  has_many :contact_people, dependent: :destroy
  has_many :people, through: :contact_people
  has_one :primary_contact_person, -> { where(primary: true) }, class_name: 'ContactPerson'
  has_one :primary_person, through: :primary_contact_person, source: :person
  has_one :spouse_contact_person, -> { where(primary: [false, nil]) }, class_name: 'ContactPerson'
  has_one :spouse, through: :spouse_contact_person, source: :person
  has_many :contact_referrals_to_me, foreign_key: :referred_to_id, class_name: 'ContactReferral', dependent: :destroy
  has_many :contact_referrals_by_me, foreign_key: :referred_by_id, class_name: 'ContactReferral', dependent: :destroy
  has_many :referrals_to_me, through: :contact_referrals_to_me, source: :referred_by
  has_many :referrals_by_me, through: :contact_referrals_by_me, source: :referred_to
  has_many :activity_contacts, dependent: :destroy
  has_many :activities, through: :activity_contacts
  has_many :tasks, through: :activity_contacts, source: :task
  has_many :notifications, inverse_of: :contact, dependent: :destroy
  has_many :messages
  has_many :appeal_contacts
  has_many :appeals, through: :appeal_contacts

  serialize :prayer_letters_params, Hash

  scope :people, -> { where('donor_accounts.master_company_id is null').includes(:donor_accounts).references('donor_accounts') }
  scope :companies, -> { where('donor_accounts.master_company_id is not null').includes(:donor_accounts).references('donor_accounts') }
  scope :with_person, -> (person) { includes(:people).where('people.id' => person.id) }
  scope :for_donor_account, -> (donor_account) { where('donor_accounts.id' => donor_account.id).includes(:donor_accounts).references('donor_accounts') }
  scope :financial_partners, -> { where(status: 'Partner - Financial') }
  scope :non_financial_partners, -> { where("status <> 'Partner - Financial' OR status is NULL") }

  scope :with_referrals, -> { joins(:contact_referrals_by_me).uniq }
  scope :active, -> { where(active_conditions) }
  scope :inactive, -> { where(inactive_conditions) }
  scope :late_by, -> (min_days, max_days = nil) { financial_partners.order(:name).to_a.keep_if { |c| c.late_by?(min_days, max_days) } }
  scope :created_between, -> (start_date, end_date) { where('contacts.created_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone) }

  PERMITTED_ATTRIBUTES = [
    :name, :pledge_amount, :status, :notes, :full_name, :greeting, :envelope_greeting, :website, :pledge_frequency,
    :pledge_start_date, :next_ask, :likely_to_give, :church_name, :send_newsletter, :no_appeals, :user_changed,
    :direct_deposit, :magazine, :pledge_received, :not_duplicated_with, :tag_list, :primary_person_id, :timezone,
    {
      contact_referrals_to_me_attributes: [:referred_by_id, :_destroy, :id],
      donor_accounts_attributes: [:account_number, :organization_id, :_destroy, :id],
      addresses_attributes: [
        :remote_id, :master_address_id, :location, :street, :city, :state, :postal_code, :region, :metro_area,
        :country, :historic, :primary_mailing_address, :_destroy, :id, :user_changed
      ],
      people_attributes: Person::PERMITTED_ATTRIBUTES
    }
  ]

  MERGE_COPY_ATTRIBUTES = [
    :name, :pledge_amount, :status, :full_name, :greeting, :envelope_greeting, :website, :pledge_frequency,
    :pledge_start_date, :next_ask, :likely_to_give, :church_name, :no_appeals, :pls_id,
    :direct_deposit, :magazine, :pledge_received, :timezone, :last_activity, :last_appointment, :last_letter,
    :last_phone_call, :last_pre_call, :last_thank, :prayer_letters_id, :last_donation_date, :first_donation_date, :tnt_id
  ]

  validates :name, presence: true
  validates :addresses, single_primary: { primary_field: :primary_mailing_address }, if: :user_changed

  accepts_nested_attributes_for :people, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :donor_accounts, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :contact_people, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :contact_referrals_to_me, reject_if: :all_blank, allow_destroy: true

  before_save :set_notes_saved_at
  after_commit :sync_with_mail_chimp, :sync_with_letter_services, :sync_with_google_contacts
  before_destroy :delete_from_letter_services, :delete_people
  LETTER_SERVICES = [:pls, :prayer_letters]

  attr_accessor :user_changed

  assignable_values_for :status, allow_blank: true do
    # Don't change these willy-nilly, they break the mobile app
    ['Never Contacted', 'Ask in Future', 'Cultivate Relationship', 'Contact for Appointment',
     'Appointment Scheduled', 'Call for Decision', 'Partner - Financial', 'Partner - Special',
     'Partner - Pray', 'Not Interested', 'Unresponsive', 'Never Ask', 'Research Abandoned',
     'Expired Referral']
  end

  IN_PROGRESS_STATUSES = ['Never Contacted', 'Ask in Future', 'Contact for Appointment', 'Appointment Scheduled',
                          'Call for Decision']

  def status=(val)
    # handle deprecated values
    case val
    when 'Call for Appointment'
      self[:status] = 'Contact for Appointment'
    else
      self[:status] = val
    end
  end

  assignable_values_for :likely_to_give, allow_blank: true do
    ['Least Likely', 'Likely', 'Most Likely']
  end

  assignable_values_for :send_newsletter, allow_blank: true do
    %w(Physical Email Both)
  end

  delegate :first_name, :last_name, :phone, :email, to: :primary_or_first_person
  delegate :street, :city, :state, :postal_code, to: :mailing_address

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

  def mailing_address
    # Use .reject(&:historic) and not .where.not(historic: true) because the
    # CSV import uses mailing_address for checking the addresses for contacts
    # before saving them to the database.
    @mailing_address ||= primary_address ||
                         addresses.reject(&:historic).first || Address.new
  end

  def reload_mailing_address
    @mailing_address = nil
    return if mailing_address.new_record?
    mailing_address.reload
  end

  def hide
    update_attributes(status: 'Never Ask')
  end

  def active?
    !Contact.inactive_statuses.include?(status)
  end

  def late_by?(min_days, max_days = nil)
    date_to_check = last_donation_date || pledge_start_date
    return false unless status == 'Partner - Financial' && pledge_frequency.present? && date_to_check.present?

    case
    when pledge_frequency >= 1.0
      late_date = date_to_check + pledge_frequency.to_i.months
    when pledge_frequency >= 0.4
      late_date = date_to_check + 2.weeks
    else
      late_date = date_to_check + 1.week
    end

    min_late_date = Date.today - min_days
    max_late_date = max_days ? Date.today - max_days : Date.new(1951, 1, 1)
    late_date > max_late_date && late_date < min_late_date
  end

  def self.active_conditions
    "status NOT IN('#{inactive_statuses.join("','")}') or status is null"
  end

  def self.inactive_conditions
    "status IN('#{inactive_statuses.join("','")}')"
  end

  def self.inactive_statuses
    ['Not Interested', 'Unresponsive', 'Never Ask', 'Research Abandoned', 'Expired Referral']
  end

  def self.create_from_donor_account(donor_account, account_list)
    contact = account_list.contacts.new(name: donor_account.name)
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

    if people.count == 1
      @primary_or_first_person = people.first
    else
      @primary_or_first_person = people.alive.find_by(gender: 'male') || people.alive.order('created_at').first
    end
    if @primary_or_first_person && @primary_or_first_person.new_record? && !self.new_record?
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
      cp.update_attributes(primary: true) if cp
    end
    person_id
  end

  def spouse_first_name
    spouse.try(:first_name)
  end

  def spouse_last_name
    spouse.try(:last_name)
  end

  def spouse_phone
    spouse.try(:spouse_phone)
  end

  def spouse_email
    spouse.try(:spouse_email)
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
      if first_names[1].present?
        return "#{first_names[0]} #{_('and')} #{first_names[1]} #{last_name}"
      else
        return "#{first_names[0]} #{last_name}"
      end
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
    pledge_amount.to_f / (pledge_frequency || 1)
  end

  def send_email_letter?
    %w(Email Both).include?(send_newsletter)
  end

  def send_physical_letter?
    %w(Physical Both).include?(send_newsletter)
  end

  def not_same_as?(other)
    not_duplicated_with.to_s.split(',').include?(other.id.to_s) ||
      other.not_duplicated_with.to_s.split(',').include?(id.to_s)
  end

  def donor_accounts_attributes=(attribute_collection)
    attribute_collection = attribute_collection.with_indifferent_access.values
    attribute_collection.each do |attrs|
      case
      when attrs[:id].present? && (attrs[:account_number].blank? || attrs[:_destroy] == '1')
        ContactDonorAccount.where(donor_account_id: attrs[:id], contact_id: id).destroy_all
      when attrs[:account_number].blank?
        next
      when donor_account = DonorAccount.find_by(account_number: attrs[:account_number], organization_id: attrs[:organization_id])
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
      (0.23076923076923).to_d => _('Weekly'),
      (0.46153846153846).to_d => _('Fortnightly'),
      (1.0).to_d => _('Monthly'),
      (2.0).to_d => _('Bi-Monthly'),
      (3.0).to_d => _('Quarterly'),
      (4.0).to_d => _('Quad-Monthly'),
      (6.0).to_d => _('Semi-Annual'),
      (12.0).to_d => _('Annual'),
      (24.0).to_d => _('Biennial')
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
        p.first_name.to_s.strip.downcase == person.first_name.to_s.strip.downcase &&
        p.last_name.to_s.strip.downcase == person.last_name.to_s.strip.downcase &&
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
    Donation.where(donor_account_id: donor_accounts.pluck(:id))
      .for_accounts(account_list.designation_accounts)
  end

  def last_donation
    donations.first
  end

  def last_monthly_total
    donations.where('donation_date >= ?', last_donation_month_end.beginning_of_month).sum(:amount)
  end

  def prev_month_donation_date
    donations.where('donation_date <= ?', (last_donation_month_end << 1).end_of_month)
      .pluck(:donation_date).first
  end

  def monthly_avg_current
    monthly_avg_over_range(current_pledge_interval_start, last_donation_month_end)
  end

  def monthly_avg_with_prev_gift
    monthly_avg_over_range(prev_donation_month_start, last_donation_month_end)
  end

  def monthly_avg_from(date)
    return unless date
    monthly_avg_over_range(start_of_pledge_interval(date), last_donation_month_end)
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

  private

  def monthly_avg_over_range(start_date, end_date)
    interval_donations(start_date, end_date).sum(:amount) / months_in_range(start_date, end_date)
  end

  def interval_donations(start_date, end_date)
    donations
      .where('donation_date >= ?', start_date)
      .where('donation_date <= ?', end_date)
  end

  def last_donation_month_end
    @recent_avg_range_end ||=
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

  def sync_with_mail_chimp
    account_list.mail_chimp_account.try(:queue_sync_contacts, [id])
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
end
