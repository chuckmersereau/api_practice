class CreateCurrencyAliases < ActiveRecord::Migration
  def change
    create_table :currency_aliases do |t|
      t.string :alias_code, null: false
      t.string :rate_api_code, null: false
      t.decimal :ratio, null: false

      t.timestamps
    end
  end
end
