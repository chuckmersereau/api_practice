class CreateCurrencyRates < ActiveRecord::Migration
  def change
    create_table :currency_rates do |t|
      t.date :exchanged_on, null: false
      t.string :code, null: false
      t.decimal :rate, precision: 20, scale: 10, null: false
      t.string :source, null: false
    end

    add_index :currency_rates, :exchanged_on
    add_index :currency_rates, :code
    add_index :currency_rates, [:code, :exchanged_on], unique: true
  end
end
