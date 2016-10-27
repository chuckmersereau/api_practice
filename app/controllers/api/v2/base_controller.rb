class Api::V2::BaseController < ActionController::Base
  before_action :jwt_authorize!

  def current_account_list
    @current_account_list ||= current_user.account_lists.first
  end

  def current_user
    @current_user ||= User.find(jwt_payload['user_id'])
  end

  private

  def jwt_payload
    @jwt_payload ||= JsonWebTonken.decode(params[:access_token])
  end
end
