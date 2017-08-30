class DesignationProfile < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  has_many :designation_profile_accounts, dependent: :delete_all
  has_many :designation_accounts, through: :designation_profile_accounts
  has_many :balances, dependent: :delete_all, as: :resource
  belongs_to :account_list
  after_save :create_balance, if: :balance_changed?
  scope :for_org, -> (org_id) { where(organization_id: org_id) }

  def to_s
    name
  end

  def designation_account
    designation_accounts.first
  end

  def merge(other)
    DesignationProfile.transaction do
      other.designation_profile_accounts.each do |da|
        designation_profile_accounts << da unless designation_profile_accounts.find { |dpa| dpa.designation_account_id == da.designation_account_id }
      end

      other.reload
      other.destroy

      save(validate: false)
    end
  end

  protected

  def create_balance
    balances.create(balance: balance) if balance
  end
end
