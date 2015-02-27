class IncreaseDonationFieldsPrecisionTake2 < ActiveRecord::Migration
  def change
    change_column :appeals, :amount, :decimal, precision: 19, scale: 2
    change_column :contacts, :pledge_amount, :decimal, precision: 19, scale: 2
    change_column :contacts, :total_donations, :decimal, precision: 19, scale: 2
    change_column :designation_accounts, :balance, :decimal, precision: 19, scale: 2
    change_column :designation_profiles, :balance, :decimal, precision: 19, scale: 2
    change_column :donations, :tendered_amount, :decimal, precision: 19, scale: 2
    change_column :donations, :amount, :decimal, precision: 19, scale: 2
    change_column :donations, :appeal_amount, :decimal, precision: 19, scale: 2
    change_column :donor_accounts, :total_donations, :decimal, precision: 19, scale: 2
  end
end
