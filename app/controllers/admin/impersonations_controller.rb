class Admin::ImpersonationsController < ApplicationController
  def create
    @impersonation = Admin::Impersonation.new(impersonation_params)
    if @impersonation.save
      sign_out(current_user)
      sign_in(@impersonation.impersonated)
      session[:impersonator_id] = @impersonation.impersonator.id
      redirect_to root_path
    else
      flash[:alert] = @impersonation.errors.full_messages.join('. ')
      redirect_to admin_home_index_path
    end
  end

  private

  def impersonation_params
    {
      user_finder: Admin::UserFinder,
      impersonation_logger: Admin::ImpersonationLog,
      impersonator: current_user,
      reason: params[:reason], impersonate_lookup: params[:impersonate_lookup]
    }
  end
end
