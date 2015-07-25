class Api::V1::MailChimpAccountsController < Api::V1::BaseController
  def available_appeal_lists
    render json: lists_available_for_appeals, callback: params[:callback]
  end

  def update
    if update_or_create
      render json: lists_available_for_appeals, callback: params[:callback]
    else
      render json: { errors: update_or_create.errors.full_messages }, callback: params[:callback], status: :bad_request
    end
  end

  private

  def lists_available_for_appeals
    current_account_list.mail_chimp_account.lists_available_for_appeals
  end

  def update_or_create
    return unless current_account_list.mail_chimp_account.nil?
    current_account_list.mail_chimp_account.queue_export_appeal_contacts
  end
end
