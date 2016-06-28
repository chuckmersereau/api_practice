class Api::V1::PreferencesController < Api::V1::BaseController
  def update
    account_list = current_user.account_lists.find(params[:id]) || current_account_list
    @preference_set = PreferenceSet.new(params[:preference_set].merge!(user: current_user, account_list: account_list))
    return render json: { preferences: @preference_set }, callback: params[:callback] if @preference_set.save
    render json: { errors: @preference_set.errors.full_messages }, callback: params[:callback], status: :bad_request
  end
end
