class CreateDeletedRecords < ActiveRecord::Migration
  def change
    create_table :deleted_records, id: :uuid do |t|
      t.uuid :account_list_id, null: false, index: true
      t.uuid :deleted_by_id
      t.datetime :deleted_on, null: false, index: true
      t.uuid :deletable_id
      t.string :deletable_type
      t.timestamps null: false
    end
    add_index :deleted_records, [:deletable_id, :deletable_type]
  end
end
