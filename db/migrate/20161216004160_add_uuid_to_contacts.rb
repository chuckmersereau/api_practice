class AddUuidToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :contacts, :uuid, unique: true
  end
end
