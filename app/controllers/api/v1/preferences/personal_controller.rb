class Api::V1::Preferences::PersonalController < Api::V1::Preferences::BaseController
  protected

  def load_preferences
    @preferences ||= {}
    load_default_preferences
    load_current_user_preferences
    load_current_account_list_preferences
  end

  private

  def load_default_preferences
    @preferences.merge!(current_user.preferences.except(:setup, :contacts_filter))
  end

  def load_current_user_preferences
    @preferences.merge!(
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      email: current_user.email.try(:email)
    )
  end

  def load_current_account_list_preferences
    @preferences.merge!(
      account_list_name: current_account_list.name,
      home_country: current_account_list.home_country,
      monthly_goal: current_account_list.monthly_goal,
      salary_organization_id: current_account_list.salary_organization_id.try(:to_s),
      currency: current_account_list.currency,
      tester: current_account_list.tester
    )
  end
end
