class Admin::OfflineOrgController < ApplicationController
  def create
    # For the sake of online orgs, query_ini_url should be unique, and
    # addresses_url should be non-nil, so just give those example values.
    Organization.create!(
      name: params[:name], query_ini_url: "#{SecureRandom.hex(8)}.example.com",
      org_help_url: params[:website],
      api_class: 'OfflineOrg', addresses_url: 'example.com')
    flash[:notice] = "Offline org #{params[:name]} created successfully."
    redirect_to admin_home_index_path
  end
end
