class AddUuidToOauthAccessTokens < ActiveRecord::Migration
  def change
    add_column :oauth_access_tokens, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :oauth_access_tokens, :uuid, unique: true
  end
end
