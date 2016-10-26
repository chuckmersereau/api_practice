class Api::V2::BaseController < ApplicationController
  before_action :doorkeeper_authorize!

  def current_account_list
    return @current_account_list if @current_account_list

    @current_account_list = current_user.account_lists.where(id: session[:current_account_list_id]).first if session[:current_account_list_id].present?
    @current_account_list ||= default_account_list
    return unless @current_account_list
    session[:current_account_list_id] = @current_account_list.id
    @current_account_list
  end
end
