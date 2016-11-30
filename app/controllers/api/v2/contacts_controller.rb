class Api::V2::ContactsController < Api::V2Controller
  def index
    load_contacts
    render json: @contacts
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
    @contact.destroy
    render_200
  end

  private

  def load_contacts
    @contacts ||= contact_scope.to_a
  end

  def load_contact
    @contact ||= Contact.find(params[:id])
  end

  def authorize_contact
    authorize @contact
  end

  def render_contact
    render json: @contact
  end

  def build_contact
    @contact ||= Contact.new
    @contact.assign_attributes(contact_params)
  end

  def save_contact
    @contact.save
  end

  def persist_contact
    build_contact
    authorize_contact
    return show if save_contact
    render_400_with_errors(@contact)
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
end
