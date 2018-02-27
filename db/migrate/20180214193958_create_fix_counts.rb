class CreateFixCounts < ActiveRecord::Migration
  def change
    create_table :fix_counts do |t|
      t.integer :account_list_id
      t.integer :old_members, default: 0
      t.integer :new_members, default: 0
      t.integer :people_changed, default: 0
      t.integer :contacts_changed, default: 0
      t.integer :contacts_tagged, default: 0
      t.timestamps null: false
      t.index :account_list_id, unique: true
    end
  end
end
