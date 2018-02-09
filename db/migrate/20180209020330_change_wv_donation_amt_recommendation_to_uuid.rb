class ChangeWvDonationAmtRecommendationToUuid < ActiveRecord::Migration
  def change
    remove_column :wv_donation_amt_recommendation, :organization_id, :integer
    add_column :wv_donation_amt_recommendation, :organization_id, :uuid
  end
end
