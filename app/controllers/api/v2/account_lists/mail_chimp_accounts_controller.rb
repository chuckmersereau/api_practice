class Api::V2::AccountLists::MailChimpAccountsController < Api::V2Controller
  def show
    load_mailchimp_account
    authorize_mailchimp_account
    render_mailchimp_account
  end

  def create
    persist_mailchimp_account
  end

  def destroy
    load_mailchimp_account
    authorize_mailchimp_account
    @mailchimp_account.destroy
    render_200
  end

  def sync
    load_mailchimp_account
    authorize_mailchimp_account
    @mailchimp_account.queue_export_to_primary_list
    render_200
  end

  private

  def load_mailchimp_account
    @mailchimp_account ||= mailchimp_account_scope
    raise ActiveRecord::RecordNotFound unless @mailchimp_account
  end

  def render_mailchimp_account
    render json: @mailchimp_account, scope: { current_account_list: load_account_list }
  end

  def persist_mailchimp_account
    build_mailchimp_account
    authorize_mailchimp_account
    return show if save_mailchimp_account
    render_400_with_errors(@mailchimp_account)
  end

  def build_mailchimp_account
    @mailchimp_account = load_account_list.build_mail_chimp_account(auto_log_campaigns: true)
    @mailchimp_account.assign_attributes(mailchimp_account_params)
    authorize_mailchimp_account
  end

  def save_mailchimp_account
    @mailchimp_account.save
  end

  def authorize_mailchimp_account
    authorize @mailchimp_account
  end

  def mailchimp_account_params
    params.require(:data).require(:attributes).permit(MailChimpAccount::PERMITTED_ATTRIBUTES)
  end

  def mailchimp_account_scope
    load_account_list.mail_chimp_account
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permited_filters
    []
  end
end
