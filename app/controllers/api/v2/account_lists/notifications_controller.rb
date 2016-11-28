class Api::V2::AccountLists::NotificationsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_notifications
    render json: @notifications
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
    @notification.destroy
    render_200
  end

  private

  def load_notifications
    @notifications ||= notification_scope.where(filter_params).to_a
  end

  def load_notification
    @notification ||= Notification.find(params[:id])
  end

  def render_notification
    render json: @notification
  end

  def persist_notification
    build_notification
    authorize_notification
    return show if save_notification
    render_400_with_errors(@notification)
  end

  def build_notification
    @notification ||= notification_scope.build
    @notification.assign_attributes(notification_params)
  end

  def save_notification
    @notification.save
  end

  def notification_params
    params.require(:data).require(:attributes).permit(Notification::PERMITTED_ATTRIBUTES)
  end

  def authorize_notification
    authorize @notification
  end

  def notification_scope
    load_account_list.notifications
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permited_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
