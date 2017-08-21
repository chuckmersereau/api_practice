class CreateDuplicateRecordPairs < ActiveRecord::Migration
  def change
    create_table :duplicate_record_pairs do |t|
      t.uuid :uuid, null: false, default: 'uuid_generate_v4()'
      t.integer :account_list_id, null: false
      t.integer :record_one_id, null: false
      t.string :record_one_type, null: false
      t.integer :record_two_id, null: false
      t.string :record_two_type, null: false
      t.string :reason, null: false
      t.boolean :ignore, default: false, null: false

      t.timestamps null: false
    end

    add_index :duplicate_record_pairs, :uuid, unique: true
    add_index :duplicate_record_pairs, [:record_one_type, :record_two_type, :record_one_id, :record_two_id], unique: true, name: 'index_dup_record_pairs_on_record_types_and_ids'
    add_index :duplicate_record_pairs, :account_list_id
    add_index :duplicate_record_pairs, [:record_one_type, :record_one_id], name: 'index_dup_record_pairs_on_record_one_type_and_record_one_id'
    add_index :duplicate_record_pairs, [:record_two_type, :record_two_id], name: 'index_dup_record_pairs_on_record_two_type_and_record_two_id'
  end
end
