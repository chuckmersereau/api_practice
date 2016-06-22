class MailChimpAccountsController < ApplicationController
  before_action :find_mail_chimp_account

  def index
    @mail_chimp_account.validate_key if current_account_list.mail_chimp_account

    unless @mail_chimp_account.active?
      redirect_to new_mail_chimp_account_path
      return
    end

    unless @mail_chimp_account.primary_list
      redirect_to edit_mail_chimp_account_path(@mail_chimp_account)
      return
    end
  end

  def create
    create_or_update
  end

  def update
    create_or_update
  end

  def new
    if $rollout.active?(:mail_chimp_auto_log, current_account_list)
      @mail_chimp_account = MailChimpAccount.new(auto_log_campaigns: true)
    end
  end

  def edit
    render :new unless @mail_chimp_account.active_and_valid?
  end

  private

  def create_or_update
    @mail_chimp_account.attributes = mail_chimp_account_params

    changed_primary = true if @mail_chimp_account.changed.include?('primary_list_id')

    if @mail_chimp_account.save && @mail_chimp_account.active?
      if @mail_chimp_account.primary_list
        if changed_primary
          flash[:notice] = _('MPDX is now syncing your newsletter recipients with MailChimp.')
        end
        redirect_to mail_chimp_accounts_path
      else
        redirect_to edit_mail_chimp_account_path(@mail_chimp_account)
      end
    else
      render :new
    end
  end

  def find_mail_chimp_account
    @mail_chimp_account = current_account_list.mail_chimp_account ||
                          current_account_list.build_mail_chimp_account
  end

  def mail_chimp_account_params
    params.require(:mail_chimp_account)
          .permit(:api_key, :grouping_id, :primary_list_id, :auto_log_campaigns)
  end
end
