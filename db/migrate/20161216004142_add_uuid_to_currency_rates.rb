class AddUuidToCurrencyRates < ActiveRecord::Migration
  def change
    add_column :currency_rates, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :currency_rates, :uuid, unique: true
  end
end
