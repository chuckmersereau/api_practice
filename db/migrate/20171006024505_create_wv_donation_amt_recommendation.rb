# This table is being created for Test and Development Environments
# On Prod there is a view being added to the database
class CreateWvDonationAmtRecommendation < ActiveRecord::Migration
  def change
    unless ActiveRecord::Base.connection.table_exists? 'wv_donation_amt_recommendation'
      create_table :wv_donation_amt_recommendation, id: false do |t|
        t.integer :organization_id
        t.string :donor_number
        t.string :designation_number
        t.decimal :previous_amount
        t.decimal :amount
        t.timestamp :started_at
        t.decimal :gift_min
        t.decimal :gift_max
        t.decimal :income_min
        t.decimal :income_max
        t.decimal :suggested_pledge_amount
        t.timestamp :ask_at
        t.string :zip_code

        t.timestamps null: false
      end
    end
  end
end
