class Api::V1::PreferencesController < Api::V1::BaseController
  def update
    build_preference
    return render json: @preference, serializer: PreferencesSetSerializer, root: 'preference' if save_preference
    render json: { errors: @preference.errors.full_messages }, status: :bad_request
  end

  protected

  def build_preference
    @preference ||= preference_scope.new(user: current_user, account_list: current_account_list)
    @preference.attributes = preference_params
  end

  def save_preference
    @preference.save
  end

  def preference_scope
    ::PreferenceSet
  end

  def preference_params
    return {} unless params[:preference]
    preference_params = params[:preference]
    notification_params = []
    NotificationType.all.each do |type|
      notification_params.push(type.class.to_s.split('::').last.to_s.underscore.to_sym => { actions: [] })
    end
    preference_params.permit(:first_name, :last_name, :email, :time_zone, :locale, :monthly_goal, :default_account_list,
                             :tester, :home_country, :ministry_country, :currency, :salary_organization_id,
                             :account_list_name, *notification_params)
  end
end
