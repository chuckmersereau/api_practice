class Api::V2::Contacts::BulkController < Api::V2Controller
  skip_before_action :transform_id_param_to_uuid_attribute

  def update
    load_contacts
    authorize_contacts
    persist_contacts
  end

  def destroy
    load_contacts
    authorize_contacts
    destroy_contacts
  end

  private

  def load_contacts
    @contacts = contact_scope.where(uuid: contact_uuid_params).tap(&:first!)
  end

  def authorize_contacts
    bulk_authorize(@contacts)
  end

  def destroy_contacts
    @destroyed_contacts = @contacts.select(&:destroy)
    render json: BulkResourceSerializer.new(resources: @destroyed_contacts)
  end

  def pundit_user
    PunditContext.new(current_user)
  end

  def contact_uuid_params
    params.require(:data).collect { |hash| hash[:data][:id] }
  end

  def contact_scope
    current_user.contacts
  end

  def persist_contacts
    build_contacts
    save_contacts
    render json: BulkResourceSerializer.new(resources: @contacts)
  end

  def save_contacts
    @contacts.each { |contact| contact.save(context: :update_from_controller) }
  end

  def build_contacts
    @contacts.each do |contact|
      contact.assign_attributes(
        contact_params(params[:data][data_attribute_index(contact)][:data][:attributes])
      )
    end
  end

  def data_attribute_index(contact)
    params[:data].find_index { |contact_data| contact_data[:data][:id] == contact.uuid }
  end

  def contact_params(attributes)
    attributes ||= params.require(:data).require(:attributes)
    attributes.permit(Contact::PERMITTED_ATTRIBUTES)
  end

  def permitted_filters
    []
  end
end
