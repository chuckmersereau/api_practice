class Api::V1::MailChimpAccountsController < Api::V1::BaseController
  def export_appeal_list
    load_mail_chimp_account
    appeal = current_account_list.appeals.find(params[:appeal_id])
    @mail_chimp_account.queue_export_appeal_contacts(params[:contact_ids], params[:appeal_list_id], appeal.id)
    render json: { success: true }
  end

  def sync
    load_mail_chimp_account
    @mail_chimp_account.queue_export_to_primary_list
    render json: { success: true }
  end

  def destroy
    load_mail_chimp_account
    @mail_chimp_account.destroy
    render json: { success: true }
  end

  private

  def load_mail_chimp_account
    @mail_chimp_account ||= current_account_list.mail_chimp_account
  end
end
