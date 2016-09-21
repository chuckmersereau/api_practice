
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
              ids = current_user.account_lists.includes(:account_list_users).map(&:account_list_users).flatten.map(&:user_id)
              User.where(id: ids).find(params[:id])
            end
  end

  def extract_session_prefs
    contacts_filter = params['user'].dig('preferences', 'contacts_filter', current_account_list.id.to_s) ||
                      params['user'].dig('contacts_filter', current_account_list.id.to_s)
    return unless contacts_filter

    session[:prefs] ||= {}
    session[:prefs][:contacts] ||= {}
    session[:prefs][:contacts][:limit] = contacts_filter['limit']
    contacts_filter.delete(:limit)
  end

  def user_params
    params.require(:user).permit(User::PERMITTED_ATTRIBUTES).tap do |whitelisted|
      whitelisted[:contacts_filter] = params[:user][:contacts_filter]
      whitelisted[:tasks_filter] = params[:user][:tasks_filter]
      whitelisted[:contacts_view_options] = params[:user][:contacts_view_options]
    end
  end
end
