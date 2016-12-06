class Api::V2::Contacts::AddressesController < Api::V2Controller
  def index
    authorize_index
    load_addresses
    render json: @addresses, meta: meta_hash(@addresses), include: include_params, fields: field_params
  end

  def show
    load_address
    authorize_address
    render_address
  end

  def create
    persist_address
  end

  def update
    load_address
    authorize_address
    persist_address
  end

  def destroy
    load_address
    authorize_address
    destroy_address
  end

  private

  def address_params
    params
      .require(:data)
      .require(:attributes)
      .permit(address_attributes)
  end

  def address_attributes
    Address::PERMITTED_ATTRIBUTES
  end

  def address_scope
    current_contact.addresses
  end

  def current_contact
    @contact ||= Contact.find_by!(uuid: params[:contact_id])
  end

  def authorize_index
    authorize(current_contact, :show?)
  end

  def authorize_address
    authorize(current_contact)
  end

  def build_address
    @address ||= address_scope.build
    @address.assign_attributes(address_params)
  end

  def destroy_address
    @address.destroy
    head :no_content
  end

  def load_address
    @address ||= address_scope.find_by!(uuid: params[:id])
  end

  def load_addresses
    @addresses = address_scope.where(filter_params)
                              .reorder(sorting_param)
                              .page(page_number_param)
                              .per(per_page_param)
  end

  def persist_address
    build_address
    authorize_address

    if save_address
      render_address
    else
      render_400_with_errors(@address)
    end
  end

  def permitted_filters
    []
  end

  def render_address
    render json: @address,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def save_address
    @address.save
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
