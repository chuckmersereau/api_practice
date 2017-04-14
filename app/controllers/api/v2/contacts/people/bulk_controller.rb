class Api::V2::Contacts::People::BulkController < Api::V2::BulkController
  resource_type :people

  def create
    build_empty_people
    persist_people
  end

  def update
    load_people
    persist_people
  end

  def destroy
    load_people
    authorize_people
    destroy_people
  end

  private

  def load_people
    @people = person_scope.where(id: person_id_params).tap(&:first!)
  end

  def authorize_people
    bulk_authorize(@people, :bulk_create?)
  end

  def destroy_people
    @destroyed_people = @people.select(&:destroy)
    render json: BulkResourceSerializer.new(resources: @destroyed_people)
  end

  def pundit_user
    PunditContext.new(current_user)
  end

  def person_id_params
    params
      .require(:data)
      .collect { |hash| hash[:person][:id] }
  end

  def person_scope
    Person.joins(:account_lists).where(account_lists: { id: account_lists })
  end

  def persist_people
    build_people
    authorize_people
    save_people
    render json: BulkResourceSerializer.new(resources: @people)
  end

  def save_people
    @people.each { |person| person.save(context: persistence_context) }
  end

  def build_empty_people
    @people = params.require(:data).map { |data| Person.new(uuid: data['person']['uuid']) }
  end

  def build_people
    @people.each do |person|
      person_index = data_attribute_index(person)
      attributes   = params.require(:data)[person_index][:person]

      person.assign_attributes(
        person_params(attributes)
      )

      if create?
        contacts = find_contacts_from_relationships(attributes[:contacts_attributes])
        person.contacts << contacts
      end

      person
    end
  end

  def find_contacts_from_relationships(contacts_data_array = nil)
    contacts_data_array ||= []
    contacts_data_array.map { |data| Contact.find(data[:id]) }
  end

  def data_attribute_index(person)
    params
      .require(:data)
      .find_index { |person_data| person_data[:person][:uuid] == person.uuid }
  end

  def person_params(attributes)
    attributes ||= params.require(:person)
    attributes.permit(Person::PERMITTED_ATTRIBUTES)
  end

  def create?
    params[:action].to_sym == :create
  end
end
