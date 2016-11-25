class Api::V2::Contacts::PeopleController < Api::V2Controller
  def index
    authorize_index
    load_people
    render json: @people, meta: meta_hash(@people)
  end

  def show
    load_person
    authorize_person
    render_person
  end

  def create
    persist_person
  end

  def update
    load_person
    authorize_person
    persist_person
  end

  def destroy
    load_person
    authorize_person
    @person.destroy
    render_200
  end

  private

  def person_params
    params
      .require(:data)
      .require(:attributes)
      .permit(person_attributes)
  end

  def person_attributes
    Person::PERMITTED_ATTRIBUTES
  end

  def person_scope
    current_contact.people.where(filter_params)
                   .reorder(sorting_param)
                   .page(page_number_param)
                   .per(per_page_param)
  end

  def current_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def authorize_index
    authorize(current_contact, :show?)
  end

  def authorize_person
    authorize(@person)
  end

  def build_person
    @person ||= person_scope.build
    @person.assign_attributes(person_params)
  end

  def load_person
    @person ||= person_scope.find(params[:id])
  end

  def load_people
    @people = person_scope
  end

  def persist_person
    build_person
    authorize_person
    return show if save_person

    render_400_with_errors(@person)
  end

  def render_person
    render json: @person
  end

  def save_person
    @person.save
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
