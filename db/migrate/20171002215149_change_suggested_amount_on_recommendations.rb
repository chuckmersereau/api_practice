class ChangeSuggestedAmountOnRecommendations < ActiveRecord::Migration
  def change
    remove_column :donation_amount_recommendations, :suggested_pledge_amount_min
    remove_column :donation_amount_recommendations, :suggested_special_amount_min
    rename_column :donation_amount_recommendations, :suggested_pledge_amount_max, :suggested_pledge_amount
    rename_column :donation_amount_recommendations, :suggested_special_amount_max, :suggested_special_amount
  end
end
