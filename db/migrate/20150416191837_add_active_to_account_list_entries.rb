class AddActiveToAccountListEntries < ActiveRecord::Migration
  def change
    add_column :account_list_entries, :active, :boolean, null: false, default: true
  end
end
