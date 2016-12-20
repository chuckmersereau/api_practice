class Api::V2::ContactsController < Api::V2Controller
  def index
    load_contacts
    render json: @contacts, meta: meta_hash(@contacts), include: include_params, fields: field_params
  end

  def show
    load_contact
    authorize_contact
    render_contact
  end

  def create
    persist_contact
  end

  def update
    load_contact
    authorize_contact
    persist_contact
  end

  def destroy
    load_contact
    authorize_contact
    destroy_contact
  end

  private

  def destroy_contact
    @contact.destroy
    head :no_content
  end

  def load_contacts
    @contacts = Contact::Filterer.new(filter_params)
                                 .filter(contact_scope, current_user)
                                 .reorder(sorting_param)
                                 .page(page_number_param)
                                 .per(per_page_param)
  end

  def load_contact
    @contact ||= Contact.find_by!(uuid: params[:id])
  end

  def authorize_contact
    authorize @contact
  end

  def render_contact
    render json: @contact,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def build_contact
    @contact ||= Contact.new
    @contact.assign_attributes(contact_params)
  end

  def save_contact
    @contact.save(context: persistence_context)
  end

  def persist_contact
    build_contact
    authorize_contact

    if save_contact
      render_contact
    else
      render_400_with_errors(@contact)
    end
  end

  def contact_params
    params.require(:data).require(:attributes).permit(contact_attributes)
  end

  def contact_attributes
    Contact::PERMITTED_ATTRIBUTES
  end

  def contact_scope
    current_user.contacts
  end

  def pundit_user
    PunditContext.new(current_user, contact: @contact)
  end

  def permitted_filters
    @permitted_filters ||= Contact::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore).collect(&:to_sym)
  end
end
