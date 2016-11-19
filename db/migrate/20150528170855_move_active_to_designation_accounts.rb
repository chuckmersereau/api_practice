class MoveActiveToDesignationAccounts < ActiveRecord::Migration
  def change
    add_column :designation_accounts, :active, :boolean, null: false, default: true
    DesignationAccount.where(id: AccountListEntry.where(active: false).pluck(:designation_account_id)).update_all(active: false)
    remove_column :account_list_entries, :active
  end
end
