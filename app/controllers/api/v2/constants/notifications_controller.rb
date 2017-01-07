class Api::V2::Constants::NotificationsController < Api::V2Controller
  def index
    load_notifications
    render_notifications
  end

  private

  def load_notifications
    @notifications ||= ::Constants::NotificationList.new
  end

  def render_notifications
    render json: @notifications
  end

  def permitted_filters
    []
  end
end
