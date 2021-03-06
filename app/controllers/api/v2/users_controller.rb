class Api::V2::UsersController < Api::V2Controller
  def show
    load_user
    authorize_user
    render_user
  end

  def update
    load_user
    authorize_user
    persist_user
  end

  private

  def load_user
    @user ||= current_user
  end

  def render_user
    render json: @user,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_user
    build_user
    authorize_user

    if save_user
      render_user
    else
      render_with_resource_errors(@user)
    end
  end

  def build_user
    @user.assign_attributes(user_params)
  end

  def save_user
    @user.save(context: persistence_context)
  end

  def user_params
    params
      .require(:user)
      .permit(User::PERMITTED_ATTRIBUTES)
  end

  def authorize_user
    authorize @user
  end

  def preferences_params
    params.dig(:user, :preferences)
  end
end
