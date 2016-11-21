class Api::V2::Appeals::ExportToMailchimpController < Api::V2::AppealsController
  def show
    load_mailchimp_account
    authorize_mailchimp_account
    @mailchimp_account.queue_export_appeal_contacts(contact_ids, params['appeal-list-id'], current_appeal.id)
    render_200
  end

  private

  def load_mailchimp_account
    @mailchimp_account ||= MailChimpAccount.first
  end

  def authorize_mailchimp_account
    authorize @mailchimp_account
  end

  def contact_ids
    current_appeal.contacts.pluck(:id)
  end

  def mailchimp_scope
    MailChimpAccount.where(filter_params)
  end

  def current_appeal
    load_appeals.find(params[:appeal_id])
  end

  def load_appeals
    @appeal ||= current_user.account_lists.find(filter_params[:account_list_id]).appeals
  end
end
