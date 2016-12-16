class AddUuidToCurrencyAliases < ActiveRecord::Migration
  def change
    add_column :currency_aliases, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :currency_aliases, :uuid, unique: true
  end
end
