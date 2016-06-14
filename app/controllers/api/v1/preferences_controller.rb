class Api::V1::PreferencesController < Api::V1::BaseController
  def index
    @preference_set = PreferenceSet.new(user: current_user, account_list: current_account_list)
    preferences = current_user.preferences.except(:setup)
    preferences = preferences.merge(fetch_all_preferences) if params[:all]
    preferences[:account_list_id] ||= current_account_list.id
    preferences[:locale] ||= locale
    render json: { preferences: preferences }, callback: params[:callback]
  end

  def update
    account_list = current_user.account_lists.find(params[:id]) || current_account_list
    @preference_set = PreferenceSet.new(params[:preference_set].merge!(user: current_user, account_list: account_list))
    return render json: { preferences: @preference_set }, callback: params[:callback] if @preference_set.save
    render json: { errors: @preference_set.errors.full_messages }, callback: params[:callback], status: :bad_request
  end

  protected

  def fetch_all_preferences
    preferences = {}
    preferences = preferences.merge(fetch_current_user_preferences)
    preferences = preferences.merge(fetch_current_account_list_preferences)
    preferences = preferences.merge(fetch_notification_preferences)
    preferences
  end

  def fetch_current_user_preferences
    {
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      email: current_user.email.try(:email),
      default_account_list: current_user.default_account_list.try(:to_s)
    }
  end

  def fetch_current_account_list_preferences
    {
      current_account_list_id: current_account_list.try(:id),
      account_list_name: current_account_list.try(:name),
      home_country: current_account_list.try(:home_country),
      monthly_goal: current_account_list.try(:monthly_goal),
      salary_organization_id: current_account_list.try(:salary_organization_id),
      currency: current_account_list.try(:currency),
      tester: current_account_list.try(:tester)
    }
  end

  def fetch_notification_preferences
    notification_preferences = {}
    NotificationType.all.each do |notification_type|
      field_name = notification_type.class.to_s.split('::').last.to_s.underscore.to_sym
      notification_preferences =
        notification_preferences.merge(
          field_name => {
            actions: [('email' if @preference_set.send(field_name).include?('email')),
                      ('task' if @preference_set.send(field_name).include?('task')),
                      '']
          }
        )
    end
    notification_preferences
  end
end
