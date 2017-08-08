class Api::V2::Admin::ResetsController < Api::V2Controller
  skip_after_action :verify_authorized

  def create
    authorize_reset
    persist_reset
  end

  private

  def authorize_reset
    raise Pundit::NotAuthorizedError,
          'must be admin level user to create resets' unless current_user.admin
  end

  def persist_reset
    build_reset
    if save_reset
      render_account_list
    else
      render_with_resource_errors(@reset)
    end
  end

  def build_reset
    @reset ||= reset_scope.new(reset_params)
  end

  def save_reset
    return Admin::Reset.delay.reset!(reset_params) if @reset.valid?
    false
  end

  def render_account_list
    render json: @reset.account_list,
           status: :ok,
           include: include_params,
           fields: field_params
  end

  def reset_scope
    ::Admin::Reset
  end

  def reset_params
    params.require(:reset)
          .permit(:resetted_user_email, :reason, :account_list_name).merge(
            user_finder: ::Admin::UserFinder,
            reset_logger: ::Admin::ResetLog,
            admin_resetting: current_user
          )
  end
end
