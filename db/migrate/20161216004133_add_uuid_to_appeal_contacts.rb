class AddUuidToAppealContacts < ActiveRecord::Migration
  def change
    add_column :appeal_contacts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :appeal_contacts, :uuid, unique: true
  end
end
