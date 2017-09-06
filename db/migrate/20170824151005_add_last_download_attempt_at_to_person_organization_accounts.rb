class AddLastDownloadAttemptAtToPersonOrganizationAccounts < ActiveRecord::Migration
  def change
    add_column :person_organization_accounts, :last_download_attempt_at, :datetime
    add_index :person_organization_accounts, :last_download_attempt_at
  end
end
