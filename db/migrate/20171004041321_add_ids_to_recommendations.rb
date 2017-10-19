class AddIdsToRecommendations < ActiveRecord::Migration
  def change
    add_belongs_to :donation_amount_recommendations,
                   :designation_account,
                   index: { name: 'recommendations_designation_account_id' },
                   foreign_key: { dependent: :nullify }
    add_belongs_to :donation_amount_recommendations,
                   :donor_account,
                   index: { name: 'recommendations_donor_account_id' },
                   foreign_key: { dependent: :nullify }
  end
end
