# WARNING: This controller is DEPRECATED, but kept for now to allow clients to migrate to the new authenticate route (which uses a different auth scheme)
class Api::V2::User::AuthenticationsController < Api::V2Controller
  skip_before_action :authenticate!, :validate_and_transform_json_api_params
  skip_after_action :verify_authorized
  before_action :load_user

  def create
    render json: { json_web_token: load_authentication },
           status: success_status,
           include: include_params,
           fields: field_params
  end

  protected

  def load_user
    @user ||= ::User.from_access_token(params[:access_token])
    raise Exceptions::AuthenticationError unless @user
    @user
  end

  def load_authentication
    @authentication ||= JsonWebToken.encode(user_uuid: @user.uuid)
  end
end
