require_dependency 'address_methods'
class DonorAccount < ApplicationRecord
  include AddressMethods

  audited associated_with: :organization, except: [:total_donations, :updated_at, :last_donation_date]

  belongs_to :organization
  belongs_to :master_company
  has_many :master_person_donor_accounts, dependent: :destroy
  has_many :master_people, through: :master_person_donor_accounts
  has_many :donor_account_people, dependent: :destroy
  has_many :people, through: :donor_account_people
  has_many :donations, dependent: :destroy
  has_many :contact_donor_accounts, dependent: :destroy
  has_many :contacts, through: :contact_donor_accounts, inverse_of: :donor_accounts
  has_many :donation_amount_recommendations, dependent: :destroy, inverse_of: :donor_account
  validates :account_number, uniqueness: { scope: :organization_id }
  validates :account_number, presence: true

  scope :filter, lambda { |account_list, filter_params|
    filtered_scope = where(filter_params.except(:wildcard_search))
    return filtered_scope unless filter_params.key?(:wildcard_search)
    filtered_scope.by_wildcard_search(account_list, filter_params[:wildcard_search])
  }

  scope :by_wildcard_search, lambda { |account_list, wildcard_search_params|
    includes(:contacts)
      .references(:contacts).where('"contacts"."name" ilike :name AND "contacts"."account_list_id" = :account_list_id OR '\
                                   '"donor_accounts"."name" ilike :name OR '\
                                   '"donor_accounts"."account_number" iLIKE :account_number',
                                   name: "%#{wildcard_search_params}%",
                                   account_number: "%#{wildcard_search_params}%",
                                   account_list_id: account_list.id)
  }

  def primary_master_person
    master_people.find_by('master_person_donor_accounts.primary' => true)
  end

  def link_to_contact_for(account_list, contact = nil)
    contact ||= account_list.contacts.where('donor_accounts.id' => id).includes(:donor_accounts).first # already linked

    # If that dind't work, try to find a contact for this user that matches based on name
    contact ||= account_list.contacts.find { |c| c.name == name }

    contact ||= Contact.create_from_donor_account(self, account_list)
    contact.donor_accounts << self unless contact.donor_accounts.include?(self)
    contact
  end

  def update_donation_totals(donation, reset: false)
    self.first_donation_date = donation.donation_date if first_donation_date.nil? || donation.donation_date < first_donation_date
    self.last_donation_date = donation.donation_date if last_donation_date.nil? || donation.donation_date > last_donation_date
    self.total_donations = reset ? total_donations_query : (total_donations.to_f + donation.amount)
    save(validate: false)
  end

  def merge(other)
    return false unless other.account_number == account_number

    self.total_donations = total_donations.to_f + other.total_donations.to_f
    self.last_donation_date = [last_donation_date, other.last_donation_date].compact.max
    self.first_donation_date = [first_donation_date, other.first_donation_date].compact.min
    self.donor_type = other.donor_type if donor_type.blank?
    self.master_company_id = other.master_company_id if master_company_id.blank?
    self.organization_id = other.organization_id if organization_id.blank?
    self.name = other.name unless attribute_present?(:name)
    save

    other.master_person_donor_accounts.each do |mpda|
      next if master_person_donor_accounts.find_by(master_person_id: mpda.master_person_id)
      mpda.update_column(:donor_account_id, id)
    end
    other.donations.update_all(donor_account_id: id)
    other.contact_donor_accounts.each do |cda|
      next if contact_donor_accounts.find { |contact_donor_account| contact_donor_account.contact_id == cda.contact_id }
      cda.update_column(:donor_account_id, id)
    end

    other.reload
    other.destroy

    true
  end

  def addresses_attributes
    attrs = %w(street city state country postal_code start_date primary_mailing_address source source_donor_account_id remote_id)
    Hash[addresses.collect.with_index { |address, i| [i, address.attributes.slice(*attrs)] }]
  end

  def name
    self[:name].presence || _('Donor')
  end

  private

  def total_donations_query
    donations.sum(:amount)
  end
end
