class RemoveAccountListId < ActiveRecord::Migration
  def change
    remove_column :deleted_records, :account_list_id
  end
end
