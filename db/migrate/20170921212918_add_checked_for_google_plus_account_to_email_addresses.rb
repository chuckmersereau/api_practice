class AddCheckedForGooglePlusAccountToEmailAddresses < ActiveRecord::Migration
  def change
    add_column :email_addresses,
               :checked_for_google_plus_account,
               :boolean,
               null: false,
               default: false
  end
end
