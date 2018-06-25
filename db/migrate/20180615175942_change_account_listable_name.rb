class ChangeAccountListableName < ActiveRecord::Migration
  def change
    add_column :deleted_records, :deleted_from_id, :uuid
    add_column :deleted_records, :deleted_from_type, :string
    add_index :deleted_records, [:deleted_from_id, :deleted_from_type], name: :deleted_from_index


    remove_index :deleted_records, name: :account_listable_index
    remove_column :deleted_records, :account_listable_id
    remove_column :deleted_records, :account_listable_type
  end
end
