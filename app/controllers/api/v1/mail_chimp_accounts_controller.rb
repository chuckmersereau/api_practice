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
    mail_chimp_appeal = MailChimpAccountAppealLists.find_by(mail_chimp_account_id:
                                                                current_account_list.mail_chimp_account.id)
    if !mail_chimp_appeal.nil?
      mail_chimp_appeal.update(appeal_list_id: params[:appeal_list_id], appeal_id: params[:appeal_id])
      else
        mail_chimp_appeal.create(mail_chimp_account_id: current_account_list.mail_chimp_account.id,
        appeal_list_id: params[:appeal_list_id], appeal_id: params[:appeal_id])
    end
  end
end

