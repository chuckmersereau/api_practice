
class Api::V1::UsersController < Api::V1::BaseController
  before_action :extract_session_prefs, only: :update

  def show
    render json: user, callback: params[:callback]
  end

  def update
    current_user.update_attributes(user_params)
    render json: user, callback: params[:callback]
  end

  private

  def user
    return @user if @user
    @user = if params[:id] == 'me'
              current_user
            else
              # Allow a user to see user information for anyone else they share an account list with
              User.where(id: current_user.account_lists.includes(:account_list_users).map(&:account_list_users).flatten.map(&:user_id)).find(params[:id])
            end
  end

  def extract_session_prefs
    return unless params['user']['preferences']['contacts_filter'][current_account_list.id.to_s]

    session[:prefs] ||= {}
    session[:prefs][:contacts] ||= {}
    session[:prefs][:contacts][:limit] = params['user']['preferences']['contacts_filter'][current_account_list.id.to_s]['limit']
    params['user']['preferences']['contacts_filter'][current_account_list.id.to_s].delete(:limit)
  end

  def user_params
    params.require(:user).permit!
  end
end
