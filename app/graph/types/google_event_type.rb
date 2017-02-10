module Types
  GoogleEventType = GraphQL::ObjectType.define do
    name 'GoogleEvent'
    description 'GoogleEvent Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :activity, ActivityType, '', property: :activity
    field :googleIntegration, GoogleIntegrationType, '', property: :google_integration
    field :googleEventId, types.String, '', property: :google_event_id
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :calendarId, types.String, '', property: :calendar_id
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
