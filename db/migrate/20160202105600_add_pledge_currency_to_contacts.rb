class AddPledgeCurrencyToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :pledge_currency, :string, limit: 4
  end
end