class CreatePledges < ActiveRecord::Migration
  def change
    create_table :pledges do |t|
      t.decimal :amount
      t.datetime :expected_date
      t.integer :donation_id
      t.integer :account_list_id
      t.integer :contact_id
      t.uuid :uuid, null: false, default: 'uuid_generate_v4()'

      t.timestamps null: false
    end

    add_index :pledges, :account_list_id
    add_index :pledges, :uuid
  end
end
