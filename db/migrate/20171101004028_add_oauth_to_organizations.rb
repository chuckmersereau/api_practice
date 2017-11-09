class AddOauthToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :oauth_url, :string
    add_column :organizations, :oauth_get_challenge_start_num_url, :string
    add_column :organizations, :oauth_get_challenge_start_num_params, :string
    add_column :organizations, :oauth_get_challenge_start_num_oauth, :string
    add_column :organizations, :oauth_convert_to_token_url, :string
    add_column :organizations, :oauth_convert_to_token_params, :string
    add_column :organizations, :oauth_convert_to_token_oauth, :string
    add_column :organizations, :oauth_get_token_info_url, :string
    add_column :organizations, :oauth_get_token_info_params, :string
    add_column :organizations, :oauth_get_token_info_oauth, :string
    add_column :organizations, :account_balance_oauth, :string
    add_column :organizations, :donations_oauth, :string
    add_column :organizations, :addresses_oauth, :string
    add_column :organizations, :addresses_by_personids_oauth, :string
    add_column :organizations, :profiles_oauth, :string
  end
end
