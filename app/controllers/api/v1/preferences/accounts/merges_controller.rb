class Api::V1::Preferences::Accounts::MergesController < Api::V1::Preferences::BaseController
  before_action :load_and_authorize_account_list, only: :create

  def create
    current_account_list.merge(@account_list_object)
    render json: { success: true }
  end

  protected

  def load_and_authorize_account_list
    return error_response('You must provide a valid account id.') if !params[:merge] || !params[:merge][:id]
    @account_list_object ||= current_user.account_lists.find(merge_params[:id])
    return error_response('You cannot merge an account with itself.') if @account_list_object == current_account_list
  end

  def merge_params
    merge_params = params[:merge]
    merge_params.permit(:id)
  end

  def load_preferences
    @preferences ||= {}
    load_merge_preferences
  end

  private

  def load_merge_preferences
    @preferences.merge!(
      mergeable_accounts: (current_user.account_lists - [current_account_list]).map { |a| { id: a.id, name: a.name } }
    )
  end

  def error_response(error_message)
    render json: { error: _(error_message) }, status: 400
    false
  end
end
