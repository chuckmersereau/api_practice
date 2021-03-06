class Appeal < ApplicationRecord
  include Filtering
  include Filtering::Contacts

  audited associated_with: :account_list, except: [:updated_at]

  attr_accessor :inclusion_filter, :exclusion_filter
  belongs_to :account_list
  has_one :mail_chimp_account, through: :account_list
  has_many :appeal_contacts, dependent: :delete_all
  has_many :contacts, through: :appeal_contacts, source: :contact
  has_many :excluded_appeal_contacts, dependent: :delete_all
  has_many :excluded_contacts, through: :excluded_appeal_contacts, source: :contact
  has_many :donations, dependent: :nullify
  has_many :pledges, dependent: :delete_all
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
                          :id].freeze

  def self.filter(filter_params)
    chain = where(filter_params.except(:wildcard_search))
    return chain unless filter_params.key?(:wildcard_search)
    chain.where('LOWER("appeals"."name") LIKE :name',
                name: "%#{filter_params[:wildcard_search].downcase}%")
  end

  def bulk_add_contacts(contacts: [], contact_ids: contacts.map(&:id))
    contact_ids_to_add = contact_ids.uniq - self.contact_ids

    appeal_contacts_to_import = contact_ids_to_add.map do |contact_id|
      AppealContact.new(contact_id: contact_id, appeal: self)
    end

    AppealContact.import(appeal_contacts_to_import)
  end

  def donated?(contact)
    donations.joins(donor_account: :contact_donor_accounts).exists?(contact_donor_accounts: { contact_id: contact.id })
  end

  def pledges_amount_total
    ConvertedTotal.new(
      pledges.joins(:contact).pluck('pledges.amount, contacts.pledge_currency, pledges.created_at'),
      account_list.salary_currency_or_default
    ).total
  end

  def pledges_amount_not_received_not_processed
    ConvertedTotal.new(
      pledges_by_status(:not_received),
      account_list.salary_currency_or_default
    ).total
  end

  def pledges_amount_received_not_processed
    ConvertedTotal.new(
      pledges_by_status(:received_not_processed),
      account_list.salary_currency_or_default
    ).total
  end

  def pledges_amount_processed
    ConvertedTotal.new(
      donations_from_pledges,
      account_list.salary_currency_or_default
    ).total
  end

  protected

  def donations_from_pledges
    donations.reorder(:created_at)
             .joins(:pledges)
             .where(pledges: { status: 'processed' })
             .pluck(:appeal_amount, :amount, :currency, :donation_date)
             .map do |donation|
      [donation[0]&.positive? ? donation[0] : donation[1], donation[2], donation[3]]
    end
  end

  def pledges_by_status(status)
    pledges.where(status: status).joins(:contact).pluck('pledges.amount, contacts.pledge_currency, pledges.created_at')
  end

  def create_contact_associations
    create_excluded_appeal_contacts_from_filter
    create_appeal_contacts_from_filter
  end

  def create_excluded_appeal_contacts_from_filter
    return unless exclusion_filter
    exclusions = {}
    exclusion_filter.each do |key, value|
      excluded_contacts_from_filter(key => value).pluck(:id).each do |id|
        exclusions[id] ||= []
        exclusions[id].append(key)
      end
    end
    bulk_add_excluded_appeal_contacts(exclusions)
  end

  def bulk_add_excluded_appeal_contacts(exclusions)
    excluded_appeal_contacts_to_import = []
    exclusions.each do |id, reasons|
      excluded_appeal_contacts_to_import << excluded_appeal_contacts.build(contact_id: id, reasons: reasons)
    end
    Appeal::ExcludedAppealContact.import(excluded_appeal_contacts_to_import)
  end

  def create_appeal_contacts_from_filter
    bulk_add_contacts(
      contact_ids: contacts_from_filter.where.not(id: excluded_appeal_contacts.select(:contact_id)).pluck(:id)
    )
  end

  def contacts_from_filter(filter = inclusion_filter)
    params = filter_params(filter)
    return Contact.none if params.empty?
    Contact::Filterer.new(params).filter(
      scope: Contact.where(account_list: account_list), account_lists: [account_list]
    )
  end

  def excluded_contacts_from_filter(filter = exclusion_filter)
    params = filter_params(filter)
    return Contact.none if params.empty?
    Contact::Filterer.new(params).filter(
      scope: contacts_from_filter, account_lists: [account_list]
    )
  end
end
