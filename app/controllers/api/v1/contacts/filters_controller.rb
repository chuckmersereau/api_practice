class Api::V1::Contacts::FiltersController < Api::V1::BaseController
  def index
    render json: { filters: Contact::Filterer.config(current_account_list) }.to_json
  end
end
