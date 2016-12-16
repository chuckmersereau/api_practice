class AddUuidToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :oauth_applications, :uuid, unique: true
  end
end
