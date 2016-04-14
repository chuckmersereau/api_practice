class MailChimpWebhookController < ApplicationController
  skip_before_action :redirect_to_mobile, :verify_authenticity_token, :ensure_setup_finished,
                     :ensure_login
  before_action :find_account_and_ensure_valid

  def index
    # used by mailchimp to verify the webhook url
    render nothing: true
  end

  def hook
    unless hook_handler_class
      render text: 'Unrecognized list id'
      return
    end

    case hook_params[:type]
    when 'subscribe'
      handler.subscribe_hook(data_param(:email))
    when 'unsubscribe'
      handler.unsubscribe_hook(data_param(:email))
    when 'upemail'
      handler.email_update_hook(data_param(:old_email), data_param(:new_email))
    when 'cleaned'
      handler.email_cleaned_hook(data_param(:email), data_param(:reason))
    when 'campaign'
      handler.campaign_status_hook(data_param(:id), data_param(:status), data_param(:subject))
    end
    render nothing: true
  end

  private

  def handler
    @handler ||= hook_handler_class.new(@account)
  end

  def hook_handler_class
    list_id = data_param(:list_id)
    if list_id == @account.primary_list_id
      MailChimpAccount::PrimaryListHookHandler
    elsif @account.mail_chimp_appeal_list &&
          list_id == @account.mail_chimp_appeal_list.appeal_list_id
      MailChimpAccount::AppealListHookHandler
    end
  end

  def find_account_and_ensure_valid
    @account = MailChimpAccount.find_by(webhook_token: params[:token])
    unless @account
      render text: 'Invalid token', status: :unauthorized
      return
    end
    unless @account.active
      render text: 'Inactive account'
      return
    end
  end

  def data_param(key)
    hook_params[:data][key]
  end

  def hook_params
    @hook_params ||=
      params.permit([:type, :fired_at,
                     { data: [:id, :list_id, :email, :email_type, :ip_opt, :ip_signup, :action, :reason,
                              :campaign_id, :new_id, :new_email, :old_email, :subject, :status,
                              { merges: [:EMAIL, :FNAME, :LNAME, :INTERESTS] }] }])
  end
end
