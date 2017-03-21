class AddValidAddressToAddresses < ActiveRecord::Migration
  def change
    add_column :addresses, :valid_values, :boolean, default: false
  end
end
