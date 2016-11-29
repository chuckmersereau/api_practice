class Api::V2::Contacts::People::EmailAddressesController < Api::V2Controller
  def index
    load_email_addresses
    authorize current_contact, :show?

    render json: @email_addresses
  end

  def show
    load_email_address
    authorize_email_address

    render_email_address
  end

  def create
    persist_email_address
  end

  def update
    load_email_address
    authorize_email_address

    persist_email_address
  end

  def destroy
    load_email_address
    authorize_email_address
    @email_address.destroy

    render_200
  end

  private

  def email_address_params
    params
      .require(:data)
      .require(:attributes)
      .permit(email_address_attributes)
  end

  def email_address_attributes
    EmailAddress::PERMITTED_ATTRIBUTES
  end

  def email_address_scope
    current_person.email_addresses
  end

  def authorize_email_address
    authorize @email_address
  end

  def build_email_address
    @email_address ||= email_address_scope.build
    @email_address.assign_attributes(email_address_params)
  end

  def load_email_address
    @email_address ||= email_address_scope.find(params[:id])
  end

  def load_email_addresses
    @email_addresses ||= email_address_scope.to_a
  end

  def persist_email_address
    build_email_address
    authorize_email_address
    return show if save_email_address

    render_400_with_errors(@email_address)
  end

  def render_email_address
    render json: @email_address
  end

  def save_email_address
    @email_address.save
  end

  def current_contact
    @current_contact ||= Contact.find(params[:contact_id])
  end

  def current_person
    @current_person ||= current_contact.people.find(params[:person_id])
  end

  def pundit_user
    return current_user if action_name == 'index'

    extra_context = {
      contact: current_contact,
      person: current_person
    }

    @pundit_user ||= PunditContext.new(current_user, extra_context)
  end
end
