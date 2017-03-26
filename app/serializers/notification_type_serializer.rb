class NotificationTypeSerializer < ApplicationSerializer
  type :notification_type

  attributes :description,
             :type

  def notification_type
    object.type
  end
end
