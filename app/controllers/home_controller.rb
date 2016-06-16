class HomeController < ApplicationController
  skip_before_action :ensure_login, only: [:login, :privacy]

  def index
    @page_title = _('Dashboard')

    check_welcome_stages
  end

  def login
    redirect_params = {
      origin: 'login',
      url: "#{OmniAuth.config.full_host}/login"
    }
    params = {
      target: 'signup',
      service: "#{OmniAuth.config.full_host}/auth/key/callback?#{redirect_params.to_query}"
    }
    @create_key_account_path = "https://thekey.me/cas/service/selfservice?#{params.to_query}"
    @create_relay_account_path = "https://thekey.me/cas/service/selfservice?#{params.merge(theme: 'relay').to_query}"

    render layout: false
  end

  def privacy
    render layout: false
  end

  def change_account_list
    session[:current_account_list_id] = params[:id] if current_user.account_lists.pluck('account_lists.id').include?(params[:id].to_i)
    redirect_to '/'
  end

  def download_data_check
    render text: current_user.organization_accounts.any?(&:downloading?)
  end

  private

  def check_welcome_stages
    user = current_user
    return unless user.setup.is_a?(Array) && user.setup.any?
    old_setup = user.setup
    user.setup = user.setup.map(&:to_sym)
    user.setup.delete :true
    dirty_preferences = true unless old_setup == user.setup
    if user.setup.include?(:import) && user.imports.count > 0
      user.setup.delete :import
      dirty_preferences = true
    end
    if user.setup.include?(:goal) && current_account_list.monthly_goal.present? &&
       current_account_list.notification_preferences.count > 1
      user.setup.delete :goal
      dirty_preferences = true
    end
    if user.setup.include?(:contacts) && current_account_list.contacts.count > 3
      user.setup.delete :contacts
      dirty_preferences = true
    end

    flash[:tour_complete] = true if dirty_preferences && user.setup.empty?
    user.save! if dirty_preferences
  end
end
