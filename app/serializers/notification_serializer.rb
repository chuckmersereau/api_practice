class NotificationSerializer < ApplicationSerializer
  attributes :cleared,
             :event_date

  has_one :contact
  has_one :notification_type

  belongs_to :donation
  belongs_to :notification_type
end
