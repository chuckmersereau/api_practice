# This model contains donation amount (recurring & one-off) recommendations for
# a donor_account in relation to a designation_account

# The data for this model is loaded in via a ETL process from the Data Warehouse
# This explains the extensive work required on the belongs_to associations for
# donor_account and designation_account as the ETL process is not aware of
# MPDX's internal ID's between models

class DonationAmountRecommendation < ApplicationRecord
  belongs_to :organization
  belongs_to :donor_account,
             (lambda do |record|
               return where(organization_id: record.organization_id) if record
               where('donor_accounts.organization_id = organization_id')
             end),
             primary_key: :account_number,
             foreign_key: :donor_number
  belongs_to :designation_account,
             (lambda do |record|
               return where(organization_id: record.organization_id) if record
               where('donor_accounts.organization_id = organization_id')
             end),
             primary_key: :designation_number,
             foreign_key: :designation_number

  validates :donor_account, :designation_account, :organization, presence: true
  validates :organization_id, uniqueness: { scope: [:donor_number, :designation_number] }
  validate :donor_account_is_of_same_organization
  validate :designation_account_is_of_same_organization

  protected

  def donor_account_is_of_same_organization
    return unless donor_account && donor_account.organization_id != organization_id
    errors[:donor_account] << 'does not have same organization'
  end

  def designation_account_is_of_same_organization
    return unless designation_account && designation_account.organization_id != organization_id
    errors[:designation_account] << 'does not have same organization'
  end
end
