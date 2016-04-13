class Admin::OfflineOrgController < ApplicationController
  def create
    if Organization.create(organization_params)
      flash[:notice] = "Offline org #{params[:name]} created successfully."
    end
    redirect_to admin_home_index_path
  end

  private

  def organization_params
    # For the sake of online orgs, query_ini_url should be unique, and
    # addresses_url should be non-nil, so just give those example values.
    {
      name: params[:name], query_ini_url: "#{SecureRandom.hex(8)}.example.com",
      org_help_url: params[:website],
      country: params[:organization][:country],
      api_class: 'OfflineOrg', addresses_url: 'example.com'
    }
  end
end
