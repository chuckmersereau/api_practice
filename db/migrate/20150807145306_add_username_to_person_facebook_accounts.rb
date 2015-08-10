class AddUsernameToPersonFacebookAccounts < ActiveRecord::Migration
  def change
    add_column :person_facebook_accounts, :username, :string
    change_column :person_facebook_accounts, :remote_id, :bigint, null: true
    add_index :person_facebook_accounts, [:person_id, :username], unique: true
  end
end
