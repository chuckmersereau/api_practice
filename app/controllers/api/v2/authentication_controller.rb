class Api::V2::AuthenticationController < ActionController::Base
  before_action :load_resource

  def create
    if @user
      render json: payload(@user)
    else
      render json: { errors: ['Invalid access token'] }, status: :unauthorized
    end
  end

  private

  def load_resource
    @user = User.from_access_token(params[:access_token])
  end

  def payload(user)
    {
      auth_token: JsonWebToken.encode(user_id: user.id),
      user: { id: user.id, email: user.email }
    }
  end
end
