class DropRecurringRecommendationResults < ActiveRecord::Migration
  def change
    drop_table :recurring_recommendation_results
  end
end
