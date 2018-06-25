class AddAccountListable < ActiveRecord::Migration
  def change
    add_column :deleted_records, :account_listable_id, :uuid
    add_column :deleted_records, :account_listable_type, :string
    add_index :deleted_records, [:account_listable_id, :account_listable_type], name: :account_listable_index
  end
end
