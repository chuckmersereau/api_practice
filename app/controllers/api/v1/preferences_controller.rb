class Api::V1::PreferencesController < Api::V1::BaseController
  def index
    @preference_set = PreferenceSet.new(user: current_user, account_list: current_account_list)
    preferences = current_user.preferences.except(:setup)
    preferences = preferences.merge(fetch_personal_preferences) if params[:personal]
    preferences = preferences.merge(fetch_notification_preferences) if params[:notifications]
    preferences = preferences.merge(fetch_integration_preferences) if params[:integrations]
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

  def fetch_personal_preferences
    preferences = fetch_required_preferences
    preferences = preferences.merge(fetch_current_user_preferences)
    preferences = preferences.merge(fetch_current_account_list_preferences)
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
      account_list_name: current_account_list.name,
      home_country: current_account_list.home_country,
      monthly_goal: current_account_list.monthly_goal,
      salary_organization_id: current_account_list.salary_organization_id.try(:to_s),
      currency: current_account_list.currency,
      tester: current_account_list.tester
    }
  end

  def fetch_integration_preferences
    {
      mail_chimp_account: current_account_list.mail_chimp_account,
      mail_chimp_account_id: current_account_list.mail_chimp_account.try(:id),
      mail_chimp_api_key: current_account_list.mail_chimp_account.try(:api_key),
      mail_chimp_primary_list_name: current_account_list.mail_chimp_account.try(:primary_list).try(:name),
      mail_chimp_auto_log_campaigns: current_account_list.mail_chimp_account.try(:auto_log_campaigns),
      valid_mail_chimp_account: current_account_list.valid_mail_chimp_account,
      prayer_letters_account: current_account_list.prayer_letters_account,
      prayer_letters_account_id: current_account_list.prayer_letters_account.try(:id),
      valid_prayer_letters_account: current_account_list.valid_prayer_letters_account,
      pls_account: current_account_list.pls_account,
      pls_account_id: current_account_list.pls_account.try(:id),
      valid_pls_account: current_account_list.valid_pls_account
    }
  end

  def fetch_required_preferences
    { current_account_list_id: current_account_list.try(:id) }
  end

  def fetch_notification_preferences
    notification_preferences = fetch_required_preferences
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
