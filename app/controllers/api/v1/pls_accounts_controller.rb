class Api::V1::PlsAccountsController < ApplicationController

  def destroy
    pls_account.destroy
    render nothing: true
  end

  def sync
    pls_account.queue_subscribe_contacts
    render nothing: true
  end

  private

  def pls_account
    @pls_account ||= current_account_list.pls_account || current_account_list.build_pls_account
  end
end
