class CreateDonationAmountRecommendations < ActiveRecord::Migration
  def change
    create_table :donation_amount_recommendations do |t|
      t.belongs_to :organization
      t.string :donor_number
      t.string :designation_number
      t.decimal :previous_amount
      t.decimal :amount
      t.timestamp :started_at
      t.decimal :gift_min
      t.decimal :gift_max
      t.decimal :income_min
      t.decimal :income_max
      t.decimal :suggested_pledge_amount_min
      t.decimal :suggested_pledge_amount_max
      t.decimal :suggested_special_amount_min
      t.decimal :suggested_special_amount_max
      t.timestamp :ask_at
      t.string :zip_code
      t.uuid :uuid, default: 'uuid_generate_v4()', null: false

      t.timestamps null: false
    end

    add_index :donation_amount_recommendations,
              [:organization_id, :designation_number, :donor_number],
              unique: true,
              name: 'index_donation_amount_recommendations'
    add_index :donation_amount_recommendations, :uuid, unique: true
  end
end
