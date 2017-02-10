module Types
  NotificationType = GraphQL::ObjectType.define do
    name 'Notification'
    description 'A Notification object'

    field :id, !types.ID, 'The UUID of the Notification', property: :uuid
    field :createdAt, !types.String, 'When the Notification was created', property: :created_at
    field :cleared, !types.String, 'The token for the Prayer Letter Account'
    field :contact, ContactType, 'The Contact that this Notification belongs to'
    field :donation, DonationType, 'The Donation that this Notification belongs to'
    field :notificationType, NotificationTypeType, 'The Notification Type that this Notification belongs to', property: :notification_type
    field :eventDate, types.String, 'The date in which this Notification took place', property: :event_date
    field :updatedAt, !types.String, 'The datetime in which the Notification was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Notification was last updated in the database', property: :updated_at
  end
end
