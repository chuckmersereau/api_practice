class AddUuidToGoogleEmails < ActiveRecord::Migration
  def change
    add_column :google_emails, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :google_emails, :uuid, unique: true
  end
end
