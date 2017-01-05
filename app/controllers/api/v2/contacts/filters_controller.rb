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

  def account_lists
    return @account_lists if @account_lists
    return @account_lists = current_user.account_lists if filter_params[:account_list_id].blank?
    @account_lists = [current_user.account_lists.find_by!(uuid: filter_params[:account_list_id])]
  end

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end
end
