class Api::V1::Preferences::Accounts::MergesController < Api::V1::Preferences::BaseController
  def create
    load_account_list
    return render json: { success: false }, status: 400 if @account_list == current_account_list
    current_account_list.merge(@account_list)
    render json: { success: true }
  end

  protected

  def load_account_list
    @account_list ||= current_user.account_lists.find(merge_params[:id])
  end

  def merge_params
    merge_params = params[:merge]
    return {} unless merge_params
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
end
