class AddValidationColumnsToEmailAddresses < ActiveRecord::Migration
  def change
    add_column :email_addresses, :valid_values, :boolean, default: true
    add_column :email_addresses, :source, :string, default: 'MPDX'
  end
end
