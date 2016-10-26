class Api::V2::BaseController < ActionController::Base
  before_action :doorkeeper_authorize!

  def current_account_list
    @current_account_list ||= current_user.account_lists.first
  end

  private

  def current_user
    @current_user ||= User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end
end
