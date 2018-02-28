class Api::V2::Contacts::PeopleController < Api::V2Controller
  supports_content_types 'multipart/form-data', 'application/vnd.api+json'

  def index
    authorize_index
    load_people

    render json: Api::V2::Contacts::PeoplePreloader.new(include_params, field_params).preload(@people),
           meta: meta_hash(@people),
           include: include_params,
           fields: field_params
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
    Contact.find(params[:contact_id])
    Contact.where(id: params[:contact_id])
  end

  def current_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def authorize_index
    return account_lists.each { |account_list| authorize(account_list, :show?) } if params[:contact_id].blank?
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
    @person ||= Person.find(params[:id])
  end

  def load_people
    @people = Person::Filterer.new(filter_params)
                              .filter(scope: person_scope, account_lists: account_lists)
                              .reorder(sorting_param)
                              .order(:created_at)
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
      @person.contact_people.create(contact: contact_scope.order(:created_at).first) if action_name == 'create' && person_save_result
      person_save_result
    end
  end

  def pundit_user
    PunditContext.new(current_user, contact_scope: contact_scope)
  end

  def permitted_filters
    @permitted_filters ||= Person::Filterer.filter_params
  end
end
