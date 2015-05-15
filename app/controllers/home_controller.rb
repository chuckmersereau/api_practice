class HomeController < ApplicationController
  skip_before_action :ensure_login, only: [:login, :privacy]

  def index
    @page_title = _('Dashboard')
  end

  def connect
    redirect_to '/#dash-connect' && return unless request.xhr?
  end

  def cultivate
    redirect_to '/#dash-cultivate' && return unless request.xhr?
  end

  def care
    redirect_to '/#dash-care' && return unless request.xhr?
  end

  def login
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
end
