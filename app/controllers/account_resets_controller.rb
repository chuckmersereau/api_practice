class AccountResetsController < ApplicationController
  def create
    AccountList::Reset.new(current_account_list, current_user)
                      .reset_shallow_and_queue_deep
    flash[:notice] = format(_('Account: %{account} has been reset.'),
                            account: current_account_list.name)
    redirect_to root_path
  end
end
