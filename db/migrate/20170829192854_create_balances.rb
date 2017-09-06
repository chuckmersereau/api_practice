class CreateBalances < ActiveRecord::Migration
  def change
    create_table :balances do |t|
      t.decimal :balance
      t.integer :resource_id
      t.string :resource_type
      t.uuid :uuid, default: 'uuid_generate_v4()'

      t.timestamps null: false
    end

    add_index :balances, [:resource_id, :resource_type]
  end
end
