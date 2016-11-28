class Api::V2::Contacts::People::PhonesController < Api::V2Controller
  def index
    authorize_index
    load_phones
    render json: @phones
  end

  def show
    load_phone
    authorize_phone
    render_phone
  end

  def create
    persist_phone
  end

  def update
    load_phone
    authorize_phone
    persist_phone
  end

  def destroy
    load_phone
    authorize_phone
    @phone.destroy
    render_200
  end

  private

  def phone_params
    params
      .require(:data)
      .require(:attributes)
      .permit(phone_attributes)
  end

  def phone_attributes
    PhoneNumber::PERMITTED_ATTRIBUTES
  end

  def phone_scope
    current_person.phone_numbers
  end

  def current_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def current_person
    @person ||= current_contact.people.find(params[:person_id])
  end

  def authorize_index
    authorize(current_person, :show?)
  end

  def authorize_phone
    authorize(current_person, :show?)
    authorize(@phone)
  end

  def build_phone
    @phone ||= phone_scope.build
    @phone.assign_attributes(phone_params)
  end

  def load_phone
    @phone ||= phone_scope.find(params[:id])
  end

  def load_phones
    @phones ||= phone_scope.to_a
  end

  def persist_phone
    build_phone
    authorize_phone
    return show if save_phone

    render_400_with_errors(@phone)
  end

  def render_phone
    render json: @phone
  end

  def save_phone
    @phone.save
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
