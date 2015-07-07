class Api::V1::MailChimpAccountsController < ApplicationController
  def index
    render json: lists_available_for_appeals, callback: params[:callback]
  end

  def update
    update_list
  end

  private

  def lists_available_for_appeals
    current_account_list.mail_chimp_account.lists_available_for_appeals
  end

  def update_list

  end

end
