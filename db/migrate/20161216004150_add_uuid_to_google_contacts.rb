class AddUuidToGoogleContacts < ActiveRecord::Migration
  def change
    add_column :google_contacts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :google_contacts, :uuid, unique: true
  end
end
