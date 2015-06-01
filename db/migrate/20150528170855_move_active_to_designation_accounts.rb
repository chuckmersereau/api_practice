class MoveActiveToDesignationAccounts < ActiveRecord::Migration
  def change
    add_column :designation_accounts, :active, :boolean, null: false, default: true
    DesignationAccount.joins(:account_list_entries)
      .where(account_list_entries: {active: false}).update_all(active: false)
    remove_column :account_list_entries, :active
  end
end
