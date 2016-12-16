class AddUuidToAppealExcludedAppealContacts < ActiveRecord::Migration
  def change
    add_column :appeal_excluded_appeal_contacts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :appeal_excluded_appeal_contacts, :uuid, unique: true
  end
end
