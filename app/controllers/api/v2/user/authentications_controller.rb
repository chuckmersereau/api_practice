class Api::V2::User::AuthenticationsController < Api::V2Controller
  skip_before_action :jwt_authorize!, :transform_params_field_names
  skip_after_action :verify_authorized
  before_action :load_user

  def create
    render json: { json_web_token: load_authentication },
           status: success_status
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
