class Api::V2::AccountLists::NotificationsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_notifications
    render json: @notifications,
           scope: { account_list: load_account_list, locale: locale },
           meta: meta_hash(@notifications),
           include: include_params,
           fields: field_params
  end

  def show
    load_notification
    authorize_notification
    render_notification
  end

  def create
    persist_notification
  end

  def update
    load_notification
    authorize_notification
    persist_notification
  end

  def destroy
    load_notification
    authorize_notification
    destroy_notification
  end

  private

  def destroy_notification
    @notification.destroy
    head :no_content
  end

  def load_notifications
    @notifications = notification_scope.where(filter_params)
                                       .reorder(sorting_param)
                                       .page(page_number_param)
                                       .per(per_page_param)
  end

  def load_notification
    @notification ||= Notification.find_by_uuid_or_raise!(params[:id])
  end

  def render_notification
    render json: @notification,
           scope: { account_list: @account_list, locale: locale },
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_notification
    build_notification
    authorize_notification

    if save_notification
      render_notification
    else
      render_with_resource_errors(@notification)
    end
  end

  def build_notification
    @notification ||= notification_scope.build
    @notification.assign_attributes(notification_params)
  end

  def save_notification
    @notification.save(context: persistence_context)
  end

  def notification_params
    params
      .require(:notification)
      .permit(Notification::PERMITTED_ATTRIBUTES)
  end

  def authorize_notification
    authorize @notification
  end

  def notification_scope
    load_account_list.notifications
  end

  def load_account_list
    @account_list ||= AccountList.find_by_uuid_or_raise!(params[:account_list_id])
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
