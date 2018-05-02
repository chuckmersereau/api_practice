class Api::V2::Contacts::BulkController < Api::V2::BulkController
  resource_type :contacts

  def create
    build_empty_contacts
    persist_contacts
  end

  def update
    load_contacts
    persist_contacts
  end

  def destroy
    load_contacts
    authorize_contacts
    destroy_contacts
  end

  private

  def load_contacts
    @contacts = contact_scope.where(id: contact_id_params).tap(&:first!)
  end

  def authorize_contacts
    bulk_authorize(@contacts)
  end

  def destroy_contacts
    @destroyed_contacts = @contacts.select(&:destroy)

    render_contacts(@destroyed_contacts)
  end

  def pundit_user
    PunditContext.new(current_user)
  end

  def contact_id_params
    params
      .require(:data)
      .collect { |hash| hash[:contact][:id] }
  end

  def contact_scope
    current_user.contacts
  end

  def persist_contacts
    build_contacts
    authorize_contacts
    save_contacts
    render_contacts(@contacts)
  end

  def render_contacts(contacts)
    render json: BulkResourceSerializer.new(resources: contacts),
           include: include_params,
           fields: field_params
  end

  def save_contacts
    @contacts.each { |contact| contact.save(context: persistence_context) }
  end

  def build_empty_contacts
    @contacts = params.require(:data).map { |data| Contact.new(id: data['contact']['id']) }
  end

  def build_contacts
    @contacts.each do |contact|
      contact_index = data_attribute_index(contact)
      attributes    = params.require(:data)[contact_index][:contact]

      contact.assign_attributes(
        contact_params(attributes)
      )
    end
  end

  def data_attribute_index(contact)
    params
      .require(:data)
      .find_index { |contact_data| contact_data[:contact][:id] == contact.id }
  end

  def contact_params(attributes)
    attributes ||= params.require(:contact)
    attributes.permit(Contact::PERMITTED_ATTRIBUTES)
  end
end
