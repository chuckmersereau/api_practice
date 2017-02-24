class Api::V2::Contacts::FiltersController < Api::V2Controller
  def index
    authorize_index
    load_filters
    render json: @filters, include: include_params, fields: field_params, each_serializer: ApplicationFilterSerializer
  end

  private

  def load_filters
    @filters ||= Contact::Filterer.config(account_lists)
  end

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def permitted_filters
    [:account_list_id]
  end
end
