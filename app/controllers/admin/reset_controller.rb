class Admin::ResetController < ApplicationController
  def create
    @reset = Admin::Reset.new(reset_params)
    if @reset.reset!
      flash[:success] = _('The user was successfully resetted.')
      redirect_to admin_home_index_path
    else
      flash[:alert] = @reset.errors.full_messages.join('. ')
      redirect_to admin_home_index_path
    end
  end

  private

  def reset_params
    {
      user_finder: Admin::UserFinder,
      reset_logger: Admin::ResetLog,
      reason: params[:reason],
      resetted_user_email: params[:resetted_user_email],
      admin_resetting: current_user
    }
  end
end
