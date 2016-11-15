class Api::V2::AccountLists::MailChimpAccountsController < Api::V2::AccountListsController
  def sync
    load_resource
    authorize @resource
    @resource.queue_export_to_primary_list
    render_200
  end

  private

  def load_resource
    @resource ||= resource_scope
    raise ActiveRecord::RecordNotFound unless @resource
  end

  def build_resource
    @resource = current_account_list.build_mail_chimp_account(auto_log_campaigns: true)
    @resource.assign_attributes(resource_params)
    authorize @resource
  end

  def resource_class
    MailChimpAccount
  end

  def resource_scope
    current_account_list.mail_chimp_account
  end

  def render_resource
    render json: @resource, scope: { current_account_list: current_account_list }
  end
end
