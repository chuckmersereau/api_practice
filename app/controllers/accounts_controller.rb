class AccountsController < ApplicationController
  skip_before_action :ensure_login, only: :create
  skip_before_action :ensure_setup_finished, only: :create

  def index
    @page_title = _('Accounts')
    @providers = %w(google facebook key organization)
  end

  def new
    respond_to do |format|
      format.js
      format.html do
        @page_title = _('New Account')
        session[:user_return_to] = params[:redirect] if params[:redirect]
        redirect_to "/auth/#{params[:provider]}"
      end
    end
  end

  def create
    provider = "Person::#{params[:provider].camelcase}Account".constantize

    sign_out(current_user) if user_signed_in? && params['origin'] == 'login'

    unless user_signed_in?
      session[:signed_in_with] = params[:provider]
      sign_in(User.from_omniauth(provider, request.env['omniauth.auth']))
      session[:user_return_to] ||= '/'

      # queue up data imports
      current_user.queue_imports
      current_account_list.async(:update_geocodes) if current_account_list
    end

    # Connect this account to the user
    @account = provider.find_or_create_from_auth(request.env['omniauth.auth'], current_user)

    redirect_to redirect_path
    session[:user_return_to] = nil
  rescue Person::Account::NoSessionError
    redirect_to '/'
  end

  def destroy
    # if they're trying to delete a key or relay account, make sure they have at least
    # one way to log in
    if %w(key relay).include?(params[:provider])
      unless current_user.key_accounts.length > 1
        redirect_to redirect_path, alert: _("If we let you delete that account you won't be able to log in anymore")
        return
      end
    end
    base = current_user.send("#{params[:provider]}_accounts".to_sym)
    base.find(params[:id]).destroy
    redirect_to redirect_path
  end

  def failure
    flash[:alert] = _('We were unable to connect your account. Please try again.')
    redirect_to redirect_path
  end

  private

  def redirect_path
    case
    when current_user.setup_mode?
      setup_path(:org_accounts)
    when session[:user_return_to]
      session[:user_return_to]
    else
      accounts_path
    end
  end
end
