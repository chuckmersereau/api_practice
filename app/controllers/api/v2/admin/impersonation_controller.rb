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
    @impersonated ||= if UUID_REGEX.match(impersonation_params[:user])
                        User.find(impersonation_params[:user])
                      else
                        find_user_by_email
                      end
  end

  def find_user_by_email
    user = User.order(:created_at).find_by_email(impersonation_params[:user])

    return user if user

    raise ActiveRecord::RecordNotFound, "Couldn't find User with email #{impersonation_params[:user]}"
  end

  def load_token
    @token ||= JsonWebToken.encode(
      user_id: load_impersonated.id,
      exp: 1.hour.from_now.utc.to_i
    )
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
