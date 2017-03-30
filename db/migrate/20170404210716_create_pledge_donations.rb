class CreatePledgeDonations < ActiveRecord::Migration
  def change
    create_table :pledge_donations do |t|
      t.integer :pledge_id
      t.integer :donation_id
      t.uuid :uuid, null: false, default: 'uuid_generate_v4()'
      t.timestamps null: false
    end
    add_index :pledge_donations, :pledge_id
    add_index :pledge_donations, :donation_id
    add_index :pledge_donations, :uuid
  end
end
