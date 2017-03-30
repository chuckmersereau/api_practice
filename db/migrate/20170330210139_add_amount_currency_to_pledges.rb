class AddAmountCurrencyToPledges < ActiveRecord::Migration
  def change
    add_column :pledges, :amount_currency, :string
  end
end
