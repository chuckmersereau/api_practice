class Api::V2::Contacts::ExportToMailChimpController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params

  def create
    require_mail_chimp_list_id
    load_mail_chimp_account
    authorize_mail_chimp_account
    raise_if_selected_list_is_primary_list
    export_to_mail_chimp
    render_200
  end

  private

  def raise_if_selected_list_is_primary_list
    return unless @mail_chimp_account.primary_list_id == params[:mail_chimp_list_id]

    raise Exceptions::BadRequestError,
          'mail_chimp_list_id cannot be primary_list_id, select different list'
  end

  def require_mail_chimp_list_id
    raise Exceptions::BadRequestError,
          'mail_chimp_list_id must be provided' unless params[:mail_chimp_list_id]
  end

  def load_mail_chimp_account
    @mail_chimp_account ||= mail_chimp_scope.mail_chimp_account
  end

  def authorize_mail_chimp_account
    authorize @mail_chimp_account
  end

  def export_to_mail_chimp
    MailChimp::ExportContactsWorker.perform_async(@mail_chimp_account.id, params[:mail_chimp_list_id], contact_ids)
  end

  def contact_ids
    @contact_ids = current_user.contacts.where(id: filter_params[:contact_ids]).ids if filter_params[:contact_ids]
    @contact_ids ||= load_appeal.contacts.ids
  end

  def mail_chimp_scope
    account_lists.first
  end

  def load_appeal
    @appeal ||= fetch_appeal
  end

  def fetch_appeal
    return account_list.appeals.first unless filter_params[:appeal_id]
    account_list.appeals.find_by!(id: filter_params[:appeal_id])
  end

  def account_list
    account_lists.first
  end

  def account_lists
    @account_lists ||= current_user.account_lists.where(id: filter_params[:account_list_id]).presence || current_user.account_lists
  end

  def permitted_filters
    [:account_list_id, :appeal_id, :contact_ids]
  end
end
