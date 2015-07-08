class Api::V1::MailChimpAccountsController < Api::V1::BaseController
  def index
    render json: lists_available_for_appeals, callback: params[:callback]
  end

  def update
    if mail_chimp_params
      render json: lists_available_for_appeals, callback: params[:callback]
    else
      render json: { errors: mail_chimp_params.errors.full_messages }, callback: params[:callback], status: :bad_request
    end
  end

  private

  def lists_available_for_appeals
    current_account_list.mail_chimp_account.lists_available_for_appeals
  end

  def mail_chimp_params
    m = MailChimpAccount.new(params[:id])
    m.export_to_list(params[:appeal_list_id],current_account_list.contact.where(id: params[:contact_ids]))
    m.update(appeal_list_id: params[:appeal_list_id], appeal_id: params[:appeal_id])
  end
end
