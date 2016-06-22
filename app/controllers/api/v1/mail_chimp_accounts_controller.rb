class Api::V1::MailChimpAccountsController < Api::V1::BaseController
  def export_appeal_list
    appeal = current_account_list.appeals.find(params[:appeal_id])
    current_account_list.mail_chimp_account
                        .queue_export_appeal_contacts(params[:contact_ids], params[:appeal_list_id], appeal.id)
    render json: { success: true }
  end

  def sync
    mail_chimp_account.queue_export_to_primary_list
    render nothing: true
  end

  def destroy
    mail_chimp_account.destroy
    render nothing: true
  end

  private

  def mail_chimp_account
    @mail_chimp_account ||= current_account_list.mail_chimp_account ||
                            current_account_list.build_mail_chimp_account
  end
end
