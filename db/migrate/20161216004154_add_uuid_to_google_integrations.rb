class AddUuidToGoogleIntegrations < ActiveRecord::Migration
  def change
    add_column :google_integrations, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :google_integrations, :uuid, unique: true
  end
end
