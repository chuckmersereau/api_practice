class Api::V2::AccountLists::MailChimpAccountsController < Api::V2Controller
  def show
    load_mail_chimp_account
    authorize_mail_chimp_account
    render_mail_chimp_account
  end

  def create
    persist_mail_chimp_account
  end

  def destroy
    load_mail_chimp_account
    authorize_mail_chimp_account
    destroy_mail_chimp_account
  end

  def sync
    load_mail_chimp_account
    authorize_mail_chimp_account
    MailChimp::PrimaryListSyncWorker.perform_async(@mail_chimp_account)
    render_200
  end

  private

  def destroy_mail_chimp_account
    @mail_chimp_account.destroy
    head :no_content
  end

  def load_mail_chimp_account
    @mail_chimp_account ||= mail_chimp_account_scope
    raise ActiveRecord::RecordNotFound unless @mail_chimp_account
  end

  def render_mail_chimp_account
    render json: @mail_chimp_account,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_mail_chimp_account
    build_mail_chimp_account
    authorize_mail_chimp_account

    if save_mail_chimp_account
      render_mail_chimp_account
    else
      render_with_resource_errors(@mail_chimp_account)
    end
  end

  def build_mail_chimp_account
    @mail_chimp_account = load_account_list.build_mail_chimp_account(auto_log_campaigns: true)
    @mail_chimp_account.assign_attributes(mail_chimp_account_params)
    authorize_mail_chimp_account
  end

  def save_mail_chimp_account
    @mail_chimp_account.save(context: persistence_context)
  end

  def authorize_mail_chimp_account
    authorize @mail_chimp_account
  end

  def mail_chimp_account_params
    params
      .require(:mail_chimp_account)
      .permit(MailChimpAccount::PERMITTED_ATTRIBUTES)
  end

  def mail_chimp_account_scope
    load_account_list.mail_chimp_account
  end

  def load_account_list
    @account_list ||= AccountList.find_by_uuid_or_raise!(params[:account_list_id])
  end
end
