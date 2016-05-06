class AppealsController < ApplicationController
  def show
    @appeal = current_account_list.appeals.find(params[:id])
  end
end
