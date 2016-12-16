class AddUuidToPersonFacebookAccounts < ActiveRecord::Migration
  def change
    add_column :person_facebook_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :person_facebook_accounts, :uuid, unique: true
  end
end
