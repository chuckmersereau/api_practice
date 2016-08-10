class AddOnlyActiveContactsToMailChimpAccounts < ActiveRecord::Migration
  def change
    add_column :mail_chimp_accounts, :sync_all_active_contacts, :boolean
  end
end
