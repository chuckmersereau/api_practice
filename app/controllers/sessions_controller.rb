class SessionsController < Devise::SessionsController
  skip_before_action :ensure_login, :ensure_setup_finished

  def destroy
    impersonator = impersonator_user
    sign_out(current_user)
    if impersonator
      sign_in(impersonator)
      session.delete(:impersonator_id)
      redirect_to admin_home_index_path
    else
      redirect_to login_path
    end
  end
end
