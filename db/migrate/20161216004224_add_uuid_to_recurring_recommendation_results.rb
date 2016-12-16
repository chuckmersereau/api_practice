class AddUuidToRecurringRecommendationResults < ActiveRecord::Migration
  def change
    add_column :recurring_recommendation_results, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :recurring_recommendation_results, :uuid, unique: true
  end
end
