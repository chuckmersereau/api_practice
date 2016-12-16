class AddUuidToGoogleEvents < ActiveRecord::Migration
  def change
    add_column :google_events, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :google_events, :uuid, unique: true
  end
end
