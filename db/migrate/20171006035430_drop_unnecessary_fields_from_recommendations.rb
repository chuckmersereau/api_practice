class DropUnnecessaryFieldsFromRecommendations < ActiveRecord::Migration
  def change
    remove_column :donation_amount_recommendations, :organization_id, :integer
    remove_column :donation_amount_recommendations, :previous_amount, :decimal
    remove_column :donation_amount_recommendations, :amount, :decimal
    remove_column :donation_amount_recommendations, :gift_min, :decimal
    remove_column :donation_amount_recommendations, :gift_max, :decimal
    remove_column :donation_amount_recommendations, :income_min, :decimal
    remove_column :donation_amount_recommendations, :income_max, :decimal
    remove_column :donation_amount_recommendations, :zip_code, :string
    remove_column :donation_amount_recommendations, :donor_number, :string
    remove_column :donation_amount_recommendations, :designation_number, :string
  end
end
