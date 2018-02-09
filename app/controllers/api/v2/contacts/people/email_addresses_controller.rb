class Api::V2::Contacts::People::EmailAddressesController < Api::V2Controller
  def index
    load_email_addresses
    authorize current_contact, :show?

    render_email_addresses
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
    persist_email_address
  end

  def destroy
    load_email_address
    authorize_email_address
    destroy_email_address
  end

  private

  def destroy_email_address
    @email_address.destroy
    head :no_content
  end

  def persist_email_address
    build_email_address
    authorize_email_address

    if save_email_address
      render_email_address
    else
      render_with_resource_errors(@email_address)
    end
  end

  def email_address_params
    params
      .require(:email_address)
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
    @email_address ||= email_address_scope.find_by!(id: params[:id])
  end

  def load_email_addresses
    @email_addresses = email_address_scope.where(filter_params)
                                          .reorder(sorting_param)
                                          .page(page_number_param)
                                          .per(per_page_param)
  end

  def render_email_address
    render json: @email_address,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def render_email_addresses
    render json: @email_addresses.preload_valid_associations(include_associations),
           meta: meta_hash(@email_addresses),
           include: include_params,
           fields: field_params
  end

  def save_email_address
    @email_address.save(context: persistence_context)
  end

  def current_contact
    @current_contact ||= Contact.find_by!(id: params[:contact_id])
  end

  def current_person
    @current_person ||= current_contact.people.find_by!(id: params[:person_id])
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact, person: current_person)
  end
end
