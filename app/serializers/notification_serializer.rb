class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :contact_id, :notification_type_id, :event_date, :cleared, :donation_id
  has_one :contact
  has_one :notification_type
end
