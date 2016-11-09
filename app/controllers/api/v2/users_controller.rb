class Api::V2::UsersController < Api::V2Controller
  def show
    load_user
    render json: @user
  end

  protected

  def load_user
    @user ||= user_scope
  end

  def user_scope
    current_user
  end
end
