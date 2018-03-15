# The source of this model's data is loaded from the BI tool into the data warehouse.
# From their a view has been created on the staging and prod instances of the MPDX database.
# Migrations exist for this model for testing and development purposes.
class DonationAmountRecommendation::Remote < ApplicationRecord
  self.table_name = 'wv_donation_amt_recommendation'

  belongs_to :organization

  # a kludge that deals with the remote id's being in the old int id format
  def organization
    return Organization.cru_usa if organization_id.to_i == 48
    super
  end

  def designation_account
    return unless organization
    organization.designation_accounts.find_by(designation_number: designation_number)
  end

  def donor_account
    return unless organization
    organization.donor_accounts.find_by(account_number: donor_number)
  end
end
