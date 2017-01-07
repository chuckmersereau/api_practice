class Constants::NotificationListSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  type :notification_list
  attributes :notifications

  def notifications
    notifications_exhibit.notifications.map do |id, notification|
      [notification.description, id]
    end.sort_by(&:first)
  end

  def notifications_exhibit
    @notifications_exhibit ||= exhibit(object)
  end
end
