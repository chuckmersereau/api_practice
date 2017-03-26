class NotificationPreferenceSerializer < ApplicationSerializer
  attributes :actions

  belongs_to :notification_type
end
