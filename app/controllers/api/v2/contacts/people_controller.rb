class Api::V2::Contacts::PeopleController < Api::V2Controller
  def index
    authorize_index
    load_people
    render json: @people, meta: meta_hash(@people), include: include_params, fields: field_params
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
    destroy_person
  end

  private

  def destroy_person
    @person.destroy
    head :no_content
  end

  def person_params
    params
      .require(:person)
      .permit(person_attributes)
  end

  def person_attributes
    Person::PERMITTED_ATTRIBUTES
  end

  def person_scope
    Person.joins(:contact_people).where(contact_people: { contact: contact_scope })
  end

  def contact_scope
    return Contact.where(account_list: account_lists) if params[:contact_id].blank?

    Contact.find_by_uuid_or_raise!(params[:contact_id])
    Contact.where(uuid: params[:contact_id])
  end

  def current_contact
    @contact ||= Contact.find_by_uuid_or_raise!(params[:contact_id])
  end

  def authorize_index
    authorize(contact_scope, :show?)
  end

  def authorize_person
    authorize(@person)
  end

  def build_person
    @person ||= person_scope.build
    @person.assign_attributes(person_params)
  end

  def load_person
    @person ||= person_scope.find_by_uuid_or_raise!(params[:id])
  end

  def load_people
    @people = Person::Filterer.new(filter_params)
                              .filter(scope: person_scope, account_lists: account_lists)
                              .reorder(sorting_param)
                              .page(page_number_param)
                              .per(per_page_param)
  end

  def persist_person
    build_person
    authorize_person

    if save_person
      render_person
    else
      render_with_resource_errors(@person)
    end
  end

  def render_person
    render json: @person,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def save_person
    ActiveRecord::Base.transaction do
      person_save_result = @person.save(context: persistence_context)
      @person.contact_people.create(contact: contact_scope.first) if action_name == 'create'
      person_save_result
    end
  end

  def pundit_user
    PunditContext.new(current_user, contacts: contact_scope)
  end

  def permitted_filters
    @permitted_filters ||= Person::Filterer.filter_params
  end
end
