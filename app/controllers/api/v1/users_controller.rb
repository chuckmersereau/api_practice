class Api::V1::UsersController < Api::V1::BaseController

  def show
    render json: current_user, callback: params[:callback]
  end

end
