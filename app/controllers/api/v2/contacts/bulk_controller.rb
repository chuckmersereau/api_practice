class Api::V2::Contacts::BulkController < Api::V2Controller
  skip_before_action :transform_id_param_to_uuid_attribute

  def update
    load_contacts_to_update
    authorize_contacts_to_update
    persist_contacts_to_update
  end

  private

  def load_contacts_to_update
    @contacts = contact_scope.where(uuid: contact_ids_from_update_list).tap(&:first!)
  end

  def authorize_contacts_to_update
    @contacts.each { |contact| authorize contact }
  end

  def persist_contacts_to_update
    build_contacts_to_update
    bulk_save_contacts
    render json: BulkUpdateSerializer.new(resources: @contacts)
  end

  def bulk_save_contacts
    @contacts.each { |contact| contact.save(context: :update_from_controller) }
  end

  def build_contacts_to_update
    @contacts.each do |contact|
      contact.assign_attributes(
        contact_params(params[:data][data_attribute_index(contact)][:attributes])
      )
    end
  end

  def data_attribute_index(contact)
    params[:data].find_index { |contact_data| contact_data[:id] == contact.uuid }
  end

  def contact_ids_from_update_list
    params[:data].map { |contact_param| contact_param['id'] }
  end

  def contact_scope
    current_user.contacts
  end

  def contact_params(attributes)
    attributes ||= params.require(:data).require(:attributes)

    attributes.permit(Contact::PERMITTED_ATTRIBUTES)
  end

  def pundit_user
    PunditContext.new(current_user, contact: @contact)
  end
end
