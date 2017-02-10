class AddDeletedToEmailAddresses < ActiveRecord::Migration
  def change
    add_column :email_addresses, :deleted, :boolean, :default => false
  end
end
