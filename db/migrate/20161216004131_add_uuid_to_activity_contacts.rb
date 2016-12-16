class AddUuidToActivityContacts < ActiveRecord::Migration
  def change
    add_column :activity_contacts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :activity_contacts, :uuid, unique: true
  end
end
