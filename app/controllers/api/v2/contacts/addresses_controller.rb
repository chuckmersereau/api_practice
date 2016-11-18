class Api::V2::Contacts::AddressesController < Api::V2Controller
  def index
    authorize_index
    load_addresses
    render json: @addresses
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
    @address.destroy
    render_200
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
    @contact ||= Contact.find(params[:contact_id])
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

  def load_address
    @address ||= address_scope.find(params[:id])
  end

  def load_addresses
    @addresses ||= address_scope.to_a
  end

  def persist_address
    build_address
    authorize_address
    return show if save_address

    render_400_with_errors(@address)
  end

  def render_address
    render json: @address
  end

  def save_address
    @address.save
  end
end
