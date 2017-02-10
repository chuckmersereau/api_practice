module Types
  NotificationPreferenceType = GraphQL::ObjectType.define do
    name 'NotificationPreference'
    description 'A Notification Preference object'

    field :id, !types.ID, 'The UUID of the Notification Preference', property: :uuid
    field :createdAt, !types.String, 'When the Notification Preference was created', property: :created_at
    field :actions, types.String, 'The action that the Notification Type takes place on, ie: "email"' do
      resolve -> (obj, args, ctx) {
        return '' unless obj.actions.present?

        obj.actions.reject { |i| i.empty? }.join(', ')
      }
    end
    field :type, types.String, 'The type of the Notification Preference'
    field :updatedAt, !types.String, 'The datetime in which the Notification Preference was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Notification Preference was last updated in the database', property: :updated_at
  end
end
