class RemoveBadFromEmailAddresses < ActiveRecord::Migration
  def change
    return unless column_exists?(:email_addresses, :bad)
    remove_column :email_addresses, :bad, :boolean
  end
end
