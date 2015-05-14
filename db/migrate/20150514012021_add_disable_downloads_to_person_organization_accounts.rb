class AddDisableDownloadsToPersonOrganizationAccounts < ActiveRecord::Migration
  def change
    add_column :person_organization_accounts, :disable_downloads, :boolean, null: false, default: false
  end
end
