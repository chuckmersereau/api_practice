class Api::V2::Contacts::People::PhonesController < Api::V2Controller
  resource_type :phone_numbers

  def index
    authorize_index
    load_phones

    render_phones
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
    persist_phone
  end

  def destroy
    load_phone
    authorize_phone
    destroy_phone
  end

  private

  def destroy_phone
    @phone.destroy
    head :no_content
  end

  def render_phones
    render json: @phones.preload_valid_associations(include_associations),
           meta: meta_hash(@phones),
           include: include_params,
           fields: field_params
  end

  def phone_params
    params
      .require(:phone_number)
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
    @phones = phone_scope.where(filter_params)
                         .reorder(sorting_param)
                         .order(default_sort_param)
                         .page(page_number_param)
                         .per(per_page_param)
  end

  def persist_phone
    build_phone
    authorize_phone

    if save_phone
      render_phone
    else
      render_with_resource_errors(@phone)
    end
  end

  def render_phone
    render json: @phone,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def save_phone
    @phone.save(context: persistence_context)
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end

  def default_sort_param
    PhoneNumber.arel_table[:created_at].asc
  end
end
