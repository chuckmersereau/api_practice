class Api::V1::SessionsController < Api::V1::BaseController
  def update
    session_params.each_pair do |key, value|
      session[key] = value if value
    end
    render nothing: true
  end

  protected

  def session_params
    session_params = params[:session]
    return {} unless session_params
    session_params.permit(:current_account_list_id)
  end
end
