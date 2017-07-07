class Api::V2::Admin::ImpersonationController < Api::V2Controller
  skip_after_action :verify_authorized

  def create
    authorize_impersonation
    persist_impersonation
    render_token
  end

  private

  def persist_impersonation
    build_impersonation_log
    save_impersonation_log
  end

  def authorize_impersonation
    raise Pundit::NotAuthorizedError,
          'must be admin level user to impersonate' unless current_user.admin
  end

  def save_impersonation_log
    @impersonation_log.save
  end

  def build_impersonation_log
    @impersonation_log ||= ::Admin::ImpersonationLog.new(
      reason: impersonation_params[:reason],
      impersonator: current_user,
      impersonated: load_impersonated
    )
  end

  def impersonation_params
    params.require(:impersonation)
          .permit(:user, :reason)
  end

  def load_impersonated
    @impersonated ||= User.find_by_uuid_or_raise!(impersonation_params[:user])
  end

  def load_token
    @token ||= JsonWebToken.encode(user_uuid: load_impersonated.uuid)
  end

  def render_token
    render json: { data: response_data },
           status: 200
  end

  def response_data
    {
      attributes: {
        json_web_token: load_token
      },
      type: 'impersonation'
    }
  end
end
