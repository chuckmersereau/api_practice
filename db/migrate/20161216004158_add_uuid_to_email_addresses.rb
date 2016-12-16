class AddUuidToEmailAddresses < ActiveRecord::Migration
  def change
    add_column :email_addresses, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :email_addresses, :uuid, unique: true
  end
end
