class Api::V1::MailChimpAccountsController < Api::V1::BaseController
  def export_appeal_list
    appeal = current_account_list.appeals.find(params[:appeal_id])
    current_account_list.mail_chimp_account
                        .queue_export_appeal_contacts(params[:contact_ids], params[:appeal_list_id], appeal.id)
    render json: { success: true }
  end
end
