class Donation < ApplicationRecord
  audited on: [:destroy]

  belongs_to :donor_account
  belongs_to :designation_account
  belongs_to :appeal

  has_many :contacts, through: :donor_account
  has_many :pledge_donations, dependent: :destroy
  has_many :pledges, through: :pledge_donations

  validates :amount, :donation_date, presence: { message: _('can not be blank') }

  scope :for, -> (designation_account) { where(designation_account_id: designation_account.id) }
  scope :for_accounts, -> (designation_accounts) { where(designation_account: designation_accounts) }
  scope :since, -> (date) { where('donation_date > ?', date) }
  scope :between, -> (from, to) { where(donation_date: from.to_date..to.to_date) }
  scope :currencies, -> { reorder(nil).pluck('DISTINCT currency') }
  scope :without_gift_aid, -> { where.not(payment_method: GIFT_AID) }

  GIFT_AID = 'Gift Aid'.freeze

  PERMITTED_ATTRIBUTES = [:amount,
                          :appeal_amount,
                          :appeal_id,
                          :channel,
                          :created_at,
                          :currency,
                          :designation_account_id,
                          :donation_date,
                          :donor_account_id,
                          :memo,
                          :motivation,
                          :overwrite,
                          :payment_method,
                          :payment_type,
                          :remote_id,
                          :tendered_amount,
                          :tendered_currency,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  # Used by Contact::DonationsEagerLoader
  attr_accessor :loaded_contact

  default_scope { order('donation_date desc') }

  scope :currencies, -> { reorder(nil).pluck('DISTINCT currency') }

  after_create :update_totals
  after_save :update_contacts, if: :donor_account_id_changed?, on: :update
  after_save :update_appeal_relations
  after_destroy :reset_totals

  before_validation :set_amount_from_tendered_amount

  def localized_amount
    amount.to_f.localize.to_currency.to_s(currency: currency)
  end

  def localized_date
    I18n.l donation_date, format: :long
  end

  def self.all_from_offline_orgs?(donations)
    org_api_classes(donations).all? { |api_class| api_class == 'OfflineOrg' }
  end

  def self.org_api_classes(donations)
    donations.reorder('').joins(:donor_account)
             .joins(donor_account: :organization).pluck('DISTINCT api_class')
  end

  def converted_amount
    CurrencyRate.convert_on_date(amount: amount,
                                 from: currency,
                                 to: converted_currency,
                                 date: donation_date)
  end

  def converted_currency
    designation_account.currency
  end

  def pledge_amount
    appeal_amount&.positive? ? appeal_amount : amount
  end

  private

  def update_contacts
    DonorAccount.find(donor_account_id_was)&.contacts&.each(&:save) if donor_account_id_was
    contacts.each(&:save)
  end

  def update_appeal_relations
    add_appeal_contacts

    # creating a pledge requires the AppealContact to be setup already
    update_related_pledge
  end

  def update_related_pledge
    pledge_match = AccountList::PledgeMatcher.new(self)
    pledge_match.pledge.donations << self if pledge_match.needs_pledge?
  end

  def update_totals(reset: false)
    donor_account&.update_donation_totals(self, reset: reset)
    designation_account&.update_donation_totals(self, reset: reset)
  end

  def reset_totals
    update_totals(reset: true)
  end

  def set_amount_from_tendered_amount
    if tendered_amount.present?
      self.tendered_amount = tendered_amount_before_type_cast.to_s.gsub(/[^\d\.\-]+/, '').to_f
      self.amount ||= tendered_amount_before_type_cast
    end
  end

  def add_appeal_contacts
    return unless appeal&.account_list

    contacts = appeal.account_list
                     .contacts
                     .joins(:contact_donor_accounts)
                     .where(contact_donor_accounts: { donor_account_id: donor_account.id })

    appeal.bulk_add_contacts(contacts: contacts)
  end
end
