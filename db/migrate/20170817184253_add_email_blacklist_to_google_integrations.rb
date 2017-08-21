class AddEmailBlacklistToGoogleIntegrations < ActiveRecord::Migration
  def change
    add_column :google_integrations, :email_blacklist, :text
  end
end
