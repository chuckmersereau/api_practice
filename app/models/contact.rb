class Contact < ActiveRecord::Base
  include AddressMethods
  acts_as_taggable

  has_many :contact_donor_accounts
  has_many :donor_accounts, through: :contact_donor_accounts
  has_many :donations, through: :donor_accounts
  belongs_to :account_list
  has_many :contact_people, dependent: :destroy
  has_many :people, through: :contact_people
  has_one  :primary_contact_person, class_name: 'ContactPerson', conditions: {primary: true}
  has_one  :primary_person, through: :primary_contact_person, source: :person
  has_one  :spouse_contact_person, class_name: 'ContactPerson', conditions: {primary: false}
  has_one  :spouse, through: :spouse_contact_person, source: :person
  has_many :contact_referrals_to_me, foreign_key: :referred_to_id, class_name: 'ContactReferral'
  has_many :contact_referrals_by_me, foreign_key: :referred_by_id, class_name: 'ContactReferral'
  has_many :referrals_to_me, through: :contact_referrals_to_me, source: :referred_by
  has_many :referrals_by_me, through: :contact_referrals_by_me, source: :referred_to
  has_many :activity_contacts
  has_many :activities, through: :activity_contacts
  has_many :tasks, through: :activity_contacts, source: :activity
  has_many :notifications, inverse_of: :contact


  scope :people, where('donor_accounts.master_company_id is null').includes(:donor_accounts)
  scope :companies, where('donor_accounts.master_company_id is not null').includes(:donor_accounts)
  scope :with_person, lambda { |person| includes(:people).where('people.id' => person.id) }
  scope :for_donor_account, lambda { |donor_account| where('donor_accounts.id' => donor_account.id).includes(:donor_accounts) }
  scope :financial_partners, where(status: 'Partner - Financial')
  scope :active, where('status NOT IN(?) or status is null', ['Not Interested', 'Unresponsive', 'Never Ask',
                               'Research Abandoned', 'Expired Referral'])


  validates :name, presence: true

  accepts_nested_attributes_for :people, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :contact_people, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :contact_referrals_to_me, reject_if: :all_blank, allow_destroy: true

  before_destroy :delete_people
  before_save    :set_notes_saved_at
  after_update   :sync_with_mail_chimp

  assignable_values_for :status, allow_blank: true do
    [_('Never Contacted'), _('Ask in Future'), _('Contact for Appointment'), _('Appointment Scheduled'),
     _('Call for Decision'), _('Partner - Financial'), _('Partner - Special'), _('Partner - Pray'),
     _('Not Interested'), _('Unresponsive'), _('Never Ask'),
    _('Research Abandoned'), _('Expired Referral')]
  end

  assignable_values_for :likely_to_give, allow_blank: true do
    [_('Least Likely'), _('Likely'), _('Most Likely')]
  end

  assignable_values_for :send_newsletter, allow_blank: true do
    [_('Physical'), _('Email'), _('Both')]
  end


  # attr_accessible :name, :addresses_attributes, :pledge_amount, :status, :contact_referrals_to_me_attributes,
  #                 :people_attributes, :notes, :contact_people_attributes, :full_name, :greeting, :website,
  #                 :pledge_frequency, :pledge_start_date, :deceased, :next_ask, :never_ask, :likely_to_give,
  #                 :church_name, :send_newsletter, :direct_deposit, :magazine, :last_activity, :last_appointment,
  #                 :last_letter, :last_phone_call, :last_pre_call, :last_thank, :tag_list

  delegate :first_name, :last_name, :phone, :email, to: :primary_or_first_person
  delegate :street, :city, :state, :postal_code, to: :mailing_address

  def to_s() name; end

  def add_person(person)
    # Nothing to do if this person is already on the contact
    new_person = people.where(master_person_id: person.master_person_id).first

    unless new_person
      new_person = Person.clone(person)
      people << new_person
    end

    new_person
  end

  def mailing_address
    @mailing_address ||= primary_address || addresses.first || Address.new
  end

  def self.create_from_donor_account(donor_account, account_list)
    contact = account_list.contacts.new({name: donor_account.name}, without_protection: true)
    contact.addresses_attributes = Hash[donor_account.addresses.collect.with_index { |address, i| [i, address.attributes.slice(*%w{street city state country postal_code})] }]
    contact.save!
    contact.donor_accounts << donor_account
    contact
  end

  def primary_or_first_person
    @primary_or_first_person ||= primary_person || people.first || Person.new
  end

  def primary_person_id
    primary_or_first_person.id
  end

  def primary_person_id=(person_id)
    cp = contact_people.where(person_id: person_id).first
    cp.update_attributes(primary: true) if cp
    person_id
  end

  def spouse_name
    spouse.try(:first_name)
  end

  def update_donation_totals(donation)
    self.first_donation_date = donation.donation_date if first_donation_date.nil? || donation.donation_date < first_donation_date
    self.last_donation_date = donation.donation_date if last_donation_date.nil? || donation.donation_date > last_donation_date
    self.total_donations = self.total_donations.to_f + donation.amount
    save(validate: false)
  end

  def monthly_pledge
    return 0 unless pledge_frequency.to_i > 0
    pledge_amount.to_f / pledge_frequency
  end

  def send_email_letter?
    %w[Email Both].include?(send_newsletter)
  end

  def merge(other)
    Contact.transaction do
      # Merge people that have the same name
      people.each do |person|
        if other_person = other.people.detect { |p| p.first_name == person.first_name &&
                                                    p.last_name == person.last_name &&
                                                    p.id != person.id }
          person.merge(other_person)
          # don't check this person next time through the loop
          other.people -= [other_person]
        end
      end

      # Update related records
      other.contact_people.each do |r|
        unless contact_people.where(person_id: r.person_id).first
          r.update_attributes({contact_id: id}, without_protection: true)
        end
      end

      %w[contact_donor_accounts activity_contacts].each do |relationship|
        other.send(relationship.to_sym).each do |r|
          r.update_attributes({contact_id: id}, without_protection: true)
        end
      end
      other.addresses.update_all(addressable_id: id)
      ContactReferral.where(referred_to_id: other.id).update_all(referred_to_id: id)
      ContactReferral.where(referred_by_id: other.id).update_all(referred_by_id: id)

      # Copy fields over updating any field that's blank on the winner
      [:name, :pledge_amount, :status, :notes, :greeting, :website,
       :pledge_frequency, :pledge_start_date, :deceased, :next_ask, :never_ask, :likely_to_give,
       :church_name, :send_newsletter, :direct_deposit, :magazine, :last_activity, :last_appointment,
       :last_letter, :last_phone_call, :last_pre_call, :last_thank].each do |field|
        if send(field).blank? && other.send(field).present?
          send("#{field}=".to_sym, other.send(field))
        end
      end
      self.tag_list += other.tag_list

      save(validate: false)
      other.reload
      other.destroy
    end
  end

  def self.pledge_frequencies
    {
      1 => _('Monthly'),
      2 => _('Bi-Monthly'),
      3 => _('Quarterly'),
      4 => _('Quad-Monthly'),
      6 => _('Semi-Annual'),
      12 => _('Annual'),
      24 => _('Biennial')
    }
  end

  private
  def delete_people
    people.each do |person|
      # If this person isn't linked to any other contact, delete them
      unless account_list.people.where("people.id = #{person.id} AND contact_people.contact_id <> #{id}").first
        person.destroy
      end
    end

    contact_people.destroy_all
  end

  def set_notes_saved_at
    self.notes_saved_at = DateTime.now if changed.include?('notes')
  end

  def sync_with_mail_chimp
    if mail_chimp_account = account_list.mail_chimp_account
      if changed.include?('send_newsletter')
        if send_email_letter?
          mail_chimp_account.queue_subscribe_contact(self)
        else
          mail_chimp_account.queue_unsubscribe_contact(self)
        end
      end
    end
  end
end

