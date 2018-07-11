class Api::V2::Contacts::ChurchNamesController < Api::V2Controller
  def index
    authorize_index
    load_churches
    render json: @church_names,
           include: include_params,
           fields: field_params,
           each_serializer: Contact::ChurchNamesSerializer
  end

  private

  def load_churches
    @church_names = search_church_names.list_church_names
  end

  def search_church_names
    return contact_scope unless params[:filter] && params[:filter][:church_name_like]
    contact_scope.search_church_names(params[:filter][:church_name_like])
  end

  def contact_scope
    Contact.where(account_list_id: account_lists.pluck(:id))
  end

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end
end
