class Api::V2::AccountLists::NotificationPreferencesController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_notification_preferences

    render json: @notification_preferences.preload_valid_associations(include_associations),
           meta: meta_hash(@notification_preferences),
           include: include_params,
           fields: field_params
  end

  def show
    load_notification_preference
    authorize_notification_preference
    render_notification_preference
  end

  def create
    persist_notification_preference
  end

  def destroy
    load_notification_preference
    authorize_notification_preference
    destroy_notification_preference
  end

  private

  def notification_preference_params
    params
      .require(:notification_preference)
      .permit(notification_preference_attributes)
  end

  def notification_preference_attributes
    NotificationPreference::PERMITTED_ATTRIBUTES
  end

  def notification_preference_scope
    # This is just a placeholder to remind you to properly scope the model
    # ie: It's meant to blow up :)
    # NotificationPreference.that_belong_to(current_user)
    load_account_list.notification_preferences
  end

  def authorize_notification_preference
    authorize @notification_preference
  end

  def build_notification_preference
    @notification_preference ||= notification_preference_scope.build
    @notification_preference.assign_attributes(notification_preference_params)
  end

  def destroy_notification_preference
    @notification_preference.destroy
    head :no_content
  end

  def load_notification_preference
    @notification_preference ||= NotificationPreference.find_by_uuid_or_raise!(params[:id])
  end

  def load_notification_preferences
    @notification_preferences ||= notification_preference_scope
                                  .where(filter_params)
                                  .page(page_number_param)
                                  .per(per_page_param)
  end

  def persist_notification_preference
    build_notification_preference
    authorize_notification_preference

    if save_notification_preference
      render_notification_preference
    else
      render_400_with_errors(@notification_preference)
    end
  end

  def render_notification_preference
    render json: @notification_preference,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def save_notification_preference
    @notification_preference.save(context: persistence_context)
  end

  def load_account_list
    @account_list ||= AccountList.find_by_uuid_or_raise!(params[:account_list_id])
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
