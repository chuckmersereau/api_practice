class Api::V1::MailChimpAccountsController < Api::V1::BaseController
  def available_appeal_lists
    render json: lists_available_for_appeals, callback: params[:callback]
  end

  def update
    if update_or_create
      render json: lists_available_for_appeals, callback: params[:callback]
    else
      render json: { errors: update_or_create.errors.full_messages },
             callback: params[:callback], status: :bad_request
    end
  end

  private

  def lists_available_for_appeals
    return unless current_account_list.mail_chimp_account.attributes.find(id: params[:id])
    current_account_list.mail_chimp_account.lists_available_for_appeals
  end

  def update_or_create
    return unless current_account_list.mail_chimp_account.attributes.find(id: params[:id])
    appeal_id = if current_account_list.appeals.find(params[:appeal_id])
                  params[:appeal_id]
                else
                  flash[:notice] = _('You have selected an invalid appeal')
                  redirect_to :back
                end
    contacts = current_account_list.mail_chimp_account.contacts_with_email_addresses(params[:contact_ids])
    current_account_list.mail_chimp_account.export_appeal_contacts(contacts, params[:appeal_list_id], appeal_id)
  end
end
