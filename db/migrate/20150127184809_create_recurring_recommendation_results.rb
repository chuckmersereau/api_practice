class CreateRecurringRecommendationResults < ActiveRecord::Migration
  def change
    create_table :recurring_recommendation_results do |t|
      t.belongs_to :account_list
      t.belongs_to :contact
      t.string :result, null: false

      t.timestamps
    end
  end
end
