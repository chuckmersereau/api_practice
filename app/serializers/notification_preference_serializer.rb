class NotificationPreferenceSerializer < ApplicationSerializer
  attributes :email, :task
  belongs_to :notification_type
end
