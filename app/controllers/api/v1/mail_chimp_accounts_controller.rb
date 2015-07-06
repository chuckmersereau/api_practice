class Api::V1::MailChimpAccountsController < ApplicationController
  def index
    render json: mail_chimp_appeals_lists,
           callback: params[:callback],
           root: :mail_chimp_accounts
  end

  private

  def mail_chimp_appeals_lists
    current_account_list.mail_chimp_account.appeals_lists
  end

end
