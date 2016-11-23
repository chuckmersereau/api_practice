class NotificationSerializer < ApplicationSerializer
  attributes :cleared,
             :contact_id,
             :donation_id,
             :event_date,
             :notification_type_id

  has_one :contact
  has_one :notification_type
end
