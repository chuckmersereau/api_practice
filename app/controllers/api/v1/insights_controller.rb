class Api::V1::InsightsController < Api::V1::BaseController
  def index
    render json: recommended_contacts, callback: params[:callback]
  end

  private

  def recommended_contacts

    Contact.where(account_list_id: current_account_list).pluck('id')

  end

end