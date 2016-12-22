class AddCreatedAtAndUpdatedAtToGoogleIntegrations < ActiveRecord::Migration
  def change
    add_column :google_integrations, :created_at, :datetime, null: false
    add_column :google_integrations, :updated_at, :datetime, null: false
  end
end
