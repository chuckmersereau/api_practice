class Api::V2::User::AuthenticationsController < Api::V2::UsersController
  skip_before_action :jwt_authorize!
  before_action :load_user

  def create
    render json: { json_web_token: load_authentication }
  end

  protected

  def load_user
    @user ||= User.from_access_token(params[:access_token])
    raise Exceptions::AuthenticationError unless @user
    @user
  end

  def load_authentication
    @authentication ||= JsonWebToken.encode(user_id: @user.id)
  end
end
