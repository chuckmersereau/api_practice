# This table is being created for Test and Development Environments
# On Prod there is a view being added to the database
class ChangeWvDonationAmtRecommendationToUuid < ActiveRecord::Migration
  def change
    remove_column :wv_donation_amt_recommendation, :organization_id, :integer
    add_column :wv_donation_amt_recommendation, :organization_id, :uuid
  end
end
