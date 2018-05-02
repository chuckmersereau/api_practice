class Api::V2::AccountLists::NotificationPreferences::BulkController < Api::V2::BulkController
  resource_type :notification_preferences

  def create
    load_notification_preferences
    persist_notification_preferences
  end

  private

  def load_notification_preferences
    @notification_preferences = notification_preference_scope.where(
      id: notification_preference_id_params.compact
    )
  end

  def authorize_notification_preferences
    bulk_authorize(@notification_preferences)
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end

  def notification_preference_id_params
    params
      .require(:data)
      .collect { |hash| hash[:notification_preference][:id] }
  end

  def notification_preference_scope
    current_user.notification_preferences.where(account_list: load_account_list)
  end

  def persist_notification_preferences
    build_empty_notification_preferences
    build_notification_preferences
    authorize_notification_preferences
    save_notification_preferences
    render json: BulkResourceSerializer.new(resources: @notification_preferences),
           include: include_params,
           fields: field_params
  end

  def save_notification_preferences
    @notification_preferences.each do |notification_preference|
      notification_preference.save(context: persistence_context)
    end
  end

  def build_empty_notification_preferences
    sent_ids = params.require(:data).map { |data| data['notification_preference']['id'] }
    existing_ids = NotificationPreference.where(id: sent_ids).pluck(:id)
    new_ids = sent_ids - existing_ids
    @notification_preferences += new_ids.map { |id| notification_preference_scope.build(id: id) }
  end

  def build_notification_preferences
    @notification_preferences.each do |notification_preference|
      notification_preference_index = data_attribute_index(notification_preference)
      attributes = params.require(:data)[notification_preference_index][:notification_preference]

      notification_preference.assign_attributes(
        notification_preference_params(attributes)
      )
    end
  end

  def data_attribute_index(notification_preference)
    params
      .require(:data)
      .find_index do |notification_preference_data|
        notification_preference_data[:notification_preference][:id] == notification_preference.id
      end
  end

  def notification_preference_params(attributes)
    attributes ||= params.require(:notification_preference)
    attributes.permit(NotificationPreference::PERMITTED_ATTRIBUTES)
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end
end
