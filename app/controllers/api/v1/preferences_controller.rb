class Api::V1::PreferencesController < Api::V1::BaseController
  def index
    preferences = current_user.preferences.except(:setup)
    preferences = preferences.merge(fetch_all_preferences) if params[:all]
    preferences[:account_list_id] ||= current_account_list.id
    preferences[:locale] ||= locale
    render json: { preferences: preferences }, callback: params[:callback]
  end

  def update
    account_list = current_user.account_lists.find(params[:id])
    account_list ||= current_account_list
    @preference_set = PreferenceSet.new(params[:preference_set].merge!(user: current_user, account_list: account_list))
    if @preference_set.save
      render json: { preferences: @preference_set }, callback: params[:callback]
    else
      render json: { errors: @preference_set.errors.full_messages }, callback: params[:callback], status: :bad_request
    end
  end

  protected

  def fetch_all_preferences
    {
      current_account_list_id: current_account_list.try(:id),
      account_list_name: current_account_list.try(:name),
      home_country: current_account_list.try(:home_country),
      monthly_goal: current_account_list.try(:monthly_goal),
      salary_organization_id: current_account_list.try(:salary_organization_id),
      currency: current_account_list.try(:currency),
      tester: current_account_list.try(:tester),
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      email: current_user.email.try(:email),
      default_account_list: current_user.default_account_list.try(:to_s)
    }
  end
end
