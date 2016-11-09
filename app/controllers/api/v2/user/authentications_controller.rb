class Api::V2::User::AuthenticationsController < Api::V2::UsersController
  skip_before_action :jwt_authorize!
  before_action :load_user

  def create
    return render text: load_authentication if @user
  end

  protected

  def load_user
    @user ||= User.from_access_token(params[:access_token])
    return @user if @user
    raise Exceptions::AuthenticationError
  end

  def load_authentication
    @authentication ||= JsonWebToken.encode(user_id: @user.id)
  end
end
