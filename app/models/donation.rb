class Donation < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  belongs_to :donor_account
  belongs_to :designation_account
  belongs_to :appeal

  validates :amount, :donation_date, presence: { message: _('can not be blank') }

  # attr_accessible :donor_account_id, :motivation, :payment_method, :tendered_currency, :donation_date, :amount, :tendered_amount, :currency, :channel, :payment_type

  scope :for, -> (designation_account) { where(designation_account_id: designation_account.id) }
  scope :for_accounts, -> (designation_accounts) { where(designation_account_id: designation_accounts.pluck(:id)) }
  scope :since, -> (date) { where('donation_date > ?', date) }
  scope :between, -> (from, to) { where(donation_date: from.to_date..to.to_date) }
  scope :currencies, -> { reorder(nil).pluck('DISTINCT currency') }

  # Used by Contact::DonationsEagerLoader
  attr_accessor :loaded_contact

  default_scope { order('donation_date desc') }

  scope :currencies, -> { reorder(nil).pluck('DISTINCT currency') }

  after_create :update_totals
  after_save :add_appeal_contacts

  before_validation :set_amount_from_tendered_amount

  def localized_amount
    amount.to_f.localize.to_currency.to_s(currency: currency)
  end

  def localized_date
    I18n.l donation_date, format: :long
  end

  private

  def update_totals
    donor_account.update_donation_totals(self)
    designation_account.update_donation_totals(self) if designation_account
  end

  def set_amount_from_tendered_amount
    if tendered_amount.present?
      self.tendered_amount = tendered_amount_before_type_cast.to_s.gsub(/[^\d\.\-]+/, '').to_f
      self.amount ||= tendered_amount_before_type_cast
    end
  end

  def add_appeal_contacts
    return unless appeal
    contacts = appeal.account_list.contacts
                     .joins(:contact_donor_accounts)
                     .where(contact_donor_accounts: { donor_account_id: donor_account.id })
    appeal.bulk_add_contacts(contacts)
  end
end
