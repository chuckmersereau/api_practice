class Api::V1::FiltersController < Api::V1::BaseController
  def index
    render json: {
      contact_filters: Contact::Filterer.config([current_account_list]),
      task_filters: Task::Filterer.config([current_account_list])
    }.to_json
  end
end
