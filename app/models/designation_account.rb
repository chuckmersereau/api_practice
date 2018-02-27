class DesignationAccount < ApplicationRecord
  belongs_to :organization
  has_many :designation_profile_accounts, dependent: :delete_all
  has_many :designation_profiles, through: :designation_profile_accounts
  has_many :account_list_entries, dependent: :delete_all
  has_many :account_lists, through: :account_list_entries
  has_many :contacts, through: :account_lists
  has_many :donations, dependent: :destroy
  has_many :balances, dependent: :delete_all, as: :resource
  has_many :donation_amount_recommendations, dependent: :destroy, inverse_of: :designation_account

  after_save :create_balance, if: :balance_changed?

  validates :organization_id, presence: true

  audited except: [:updated_at, :balance, :balance_updated_at]

  def to_s
    designation_number
  end

  # A given user should only have a designation account in one list
  def account_list(user)
    (user.account_lists & account_lists).first
  end

  def update_donation_totals(donation, reset: false)
    contacts.includes(:donor_accounts).where('donor_accounts.id' => donation.donor_account_id).find_each do |contact|
      contact.update_donation_totals(donation, reset: reset)
    end
  end

  def currency
    @currency ||= organization.default_currency_code || 'USD'
  end

  def converted_balance(convert_to_currency)
    # Log the error in rollbar, but then return a zero balance to prevent future
    # errors and prevent this balance form adding to the total.
    CurrencyRate.convert_with_latest(amount: balance, from: currency,
                                     to: convert_to_currency)
  end

  def self.filter(filter_params)
    chain = where(filter_params.except(:wildcard_search))
    return chain unless filter_params.key?(:wildcard_search)
    chain.where('LOWER("designation_accounts"."name") LIKE :name OR '\
                '"designation_accounts"."designation_number" LIKE :account_number',
                name: "%#{filter_params[:wildcard_search].downcase}%",
                account_number: "#{filter_params[:wildcard_search]}%")
  end

  protected

  def create_balance
    balances.create(balance: balance) if balance
  end
end
