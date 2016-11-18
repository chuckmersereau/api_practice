class Api::V2::Appeals::ExportToMailchimpController < Api::V2::AppealsController
  def show
    load_mailchimp_account
    authorize_mailchimp_account
    @resource.queue_export_appeal_contacts(contact_ids, params['appeal-list-id'], current_appeal.id)
    render_200
  end

  private

  def load_mailchimp_account
    @resource ||= mailchimp_scope
    raise ActiveRecord::RecordNotFound unless @resource
  end

  def authorize_mailchimp_account
    authorize @resource
  end

  def contact_ids
    current_appeal.contacts.pluck(:id)
  end

  def mailchimp_scope
    MailChimpAccount.that_belong_to(filter_params)
  end

  def current_appeal
    appeal_scope.find(params[:appeal_id])
  end

  def permited_filters
    [:account_list_id]
  end
end
