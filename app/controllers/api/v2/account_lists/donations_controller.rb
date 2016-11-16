class Api::V2::AccountLists::DonationsController < Api::V2::AccountListsController
  def index
    load_resources
    render json: @resources, scope: { account_list: current_account_list, locale: locale }
  end

  def show
    load_resource
    render json: @resource, scope: { account_list: current_account_list, locale: locale }
  end

  private

  def resource_class
    Donation
  end

  def resource_scope
    current_account_list.donations
  end
end
