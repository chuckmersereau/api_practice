class AddCreatedAtAndUpdatedAtToGoogleIntegrations < ActiveRecord::Migration
  def up
    execute('ALTER TABLE "google_integrations" ADD COLUMN "created_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP')
    execute('ALTER TABLE "google_integrations" ADD COLUMN "updated_at" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP')
  end

  def down
    remove_column :google_integrations, :created_at
    remove_column :google_integrations, :updated_at
  end
end
