class UpdatePersonGoogleAccountsRemoteIdLength < ActiveRecord::Migration
  def change
    change_column :person_google_accounts, :remote_id, :text
  end
end
