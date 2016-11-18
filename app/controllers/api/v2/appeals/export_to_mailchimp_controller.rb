class Api::V2::Appeals::ExportToMailchimpController < Api::V2::AppealsController
  def show
    @resource.queue_export_appeal_contacts(contact_ids, params['appeal-list-id'], current_appeal.id)
    render_200
  end

  private

  def load_resource
    @resource ||= resource_scope
    raise ActiveRecord::RecordNotFound unless @resource
  end

  def resource_scope
    mailchimp_scope
  end

  def contacts
    current_appeal.contacts
  end

  def contact_ids
    contacts.pluck(:id)
  end

  def mailchimp_scope
    MailChimpAccount.that_belong_to(filter_params)
  end

  def current_appeal
    appeal_scope.find(params[:appeal_id])
  end

  def permited_filters
    %w(account_list_id)
  end
end
