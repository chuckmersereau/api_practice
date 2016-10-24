class Api::V1::CurrentAccountListsController < Api::V1::BaseController
  def show
    render json: current_account_list
  end
end
