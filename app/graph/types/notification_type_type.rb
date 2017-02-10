module Types
  NotificationTypeType = GraphQL::ObjectType.define do
    name 'NotificationType'
    description 'A Notification Type object'

    field :id, !types.ID, 'The UUID of the Notification Type', property: :uuid
    field :createdAt, !types.String, 'When the Notification Type was created', property: :created_at
    field :description, types.String, 'The description of the Notification Type'
    field :descriptionForEmail, types.String, 'The description of the Notification Type for email', property: :description_for_email
    field :updatedInDbAt, !types.String, 'The datetime in which the Notification Type was last updated in the database', property: :updated_at
  end
end
