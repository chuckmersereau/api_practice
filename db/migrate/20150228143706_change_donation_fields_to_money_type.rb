class ChangeDonationFieldsToMoneyType < ActiveRecord::Migration
  def change_field_to_money(table, field)
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} ALTER COLUMN #{field} TYPE money")
  end

  def change
    change_field_to_money :appeals, :amount
    change_field_to_money :contacts, :pledge_amount
    change_field_to_money :contacts, :total_donations
    change_field_to_money :designation_accounts, :balance
    change_field_to_money :designation_profiles, :balance
    change_field_to_money :donations, :tendered_amount
    change_field_to_money :donations, :amount
    change_field_to_money :donations, :appeal_amount
    change_field_to_money :donor_accounts, :total_donations
  end
end
