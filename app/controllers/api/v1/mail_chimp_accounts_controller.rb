class Api::V1::MailChimpAccountsController < Api::V1::BaseController
  def available_appeal_lists
    render json: current_account_list.mail_chimp_account.try(:lists_available_for_appeals) || []
  end

  def export_appeal_list
    appeal = current_account_list.appeals.find(params[:appeal_id])
    current_account_list.mail_chimp_account
      .export_appeal_contacts(params[:contact_ids], params[:appeal_list_id], appeal)
    render json: { success: true }
  end
end
