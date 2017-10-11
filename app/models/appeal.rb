class Appeal < ApplicationRecord
  attr_accessor :inclusion_filter, :exclusion_filter
  belongs_to :account_list
  has_one :mail_chimp_account, through: :account_list
  has_many :appeal_contacts, dependent: :delete_all
  has_many :contacts, through: :appeal_contacts, source: :contact
  has_many :excluded_appeal_contacts, dependent: :delete_all
  has_many :excluded_contacts, through: :excluded_appeal_contacts, source: :contact
  has_many :donations
  has_many :pledges
  validates :name, :account_list_id, presence: true
  after_create :create_contact_associations
  default_scope { order(created_at: :desc) }
  scope :that_belong_to, -> (user) { where(account_list_id: user.account_list_ids) }

  PERMITTED_ATTRIBUTES = [:account_list_id,
                          :amount,
                          :description,
                          :end_date,
                          :exclusion_filter,
                          :inclusion_filter,
                          :name,
                          :overwrite,
                          :created_at,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  def self.filter(filter_params)
    chain = where(filter_params.except(:wildcard_search))
    return chain unless filter_params.key?(:wildcard_search)
    chain.where('LOWER("appeals"."name") LIKE :name',
                name: "%#{filter_params[:wildcard_search].downcase}%")
  end

  def bulk_add_contacts(contacts: [], contact_ids: contacts.map(&:id))
    contact_ids_to_add = contact_ids.uniq - self.contact_ids

    appeal_contacts_to_import = contact_ids_to_add.map do |contact_id|
      AppealContact.new(contact_id: contact_id, appeal: self, uuid: SecureRandom.uuid)
    end

    AppealContact.import(appeal_contacts_to_import)
  end

  def donated?(contact)
    donations.joins(donor_account: :contact_donor_accounts).exists?(contact_donor_accounts: { contact_id: contact.id })
  end

  def pledges_amount_total
    pledges.sum(:amount)
  end

  def pledges_amount_not_received_not_processed
    pledges.where(status: :not_received).sum(:amount)
  end

  def pledges_amount_received_not_processed
    pledges.where(status: :received_not_processed).sum(:amount)
  end

  def pledges_amount_processed
    pledges.where(status: :processed).sum(:amount)
  end

  protected

  def create_contact_associations
    create_excluded_appeal_contacts_from_filter
    create_appeal_contacts_from_filter
  end

  def create_excluded_appeal_contacts_from_filter
    return unless exclusion_filter
    exclusions = {}
    exclusion_filter.each do |key, value|
      excluded_contacts_from_filter(ActionController::Parameters.new(key => value)).pluck(:id).each do |id|
        exclusions[id] ||= []
        exclusions[id].append(key)
      end
    end
    bulk_add_excluded_appeal_contacts(exclusions)
  end

  def bulk_add_excluded_appeal_contacts(exclusions)
    excluded_appeal_contacts_to_import = []
    exclusions.each do |id, reasons|
      excluded_appeal_contacts_to_import << excluded_appeal_contacts.build(contact_id: id, reasons: reasons, uuid: SecureRandom.uuid)
    end
    Appeal::ExcludedAppealContact.import(excluded_appeal_contacts_to_import)
  end

  def create_appeal_contacts_from_filter
    bulk_add_contacts(
      contact_ids: contacts_from_filter.where.not(id: excluded_appeal_contacts.select(:contact_id)).pluck(:id)
    )
  end

  def contacts_from_filter(filter = inclusion_filter)
    return Contact.none unless filter
    Contact::Filterer.new(filter).filter(
      scope: account_list.contacts, account_lists: [account_list]
    )
  end

  def excluded_contacts_from_filter(filter = exclusion_filter)
    return Contact.none unless filter
    Contact::Filterer.new(filter).filter(
      scope: contacts_from_filter, account_lists: [account_list]
    )
  end
end
