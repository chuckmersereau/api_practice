class AddUuidToContactNotesLogs < ActiveRecord::Migration
  def change
    add_column :contact_notes_logs, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :contact_notes_logs, :uuid, unique: true
  end
end
