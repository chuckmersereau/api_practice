class AddEstimatedAnnualPledgeAmountToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :estimated_annual_pledge_amount, :decimal, precision: 19, scale: 2
  end
end
