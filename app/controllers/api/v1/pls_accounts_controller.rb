class Api::V1::PlsAccountsController < Api::V1::BaseController
  def destroy
    load_pls_account
    @pls_account.destroy
    render json: { success: true }
  end

  def sync
    load_pls_account
    @pls_account.queue_subscribe_contacts
    render json: { success: true }
  end

  private

  def load_pls_account
    @pls_account ||= current_account_list.pls_account
  end
end
