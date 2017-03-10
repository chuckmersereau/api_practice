module AuthHelper
  def auth_login(user)
    allow_any_instance_of(Auth::ApplicationController).to receive(:jwt_authorize!)
    allow_any_instance_of(Auth::ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(Auth::UserAccountsController).to receive(:fetch_current_user).and_return(user)
  end

  def auth_logout
    allow_any_instance_of(Auth::ApplicationController).to receive(:jwt_authorize!).and_raise(Exceptions::AuthenticationError)
    allow_any_instance_of(Auth::ApplicationController).to receive(:current_user).and_return(nil)
    allow_any_instance_of(Auth::UserAccountsController).to receive(:fetch_current_user).and_return(nil)
  end
end
