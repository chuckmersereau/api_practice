class AddImportingToMailChimpAccounts < ActiveRecord::Migration
  def change
    add_column :mail_chimp_accounts, :importing, :boolean, null: false, default: false
  end
end
