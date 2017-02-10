module Types
  GoogleIntegrationType = GraphQL::ObjectType.define do
    name 'GoogleIntegration'
    description 'GoogleIntegration Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :accountListId, types.Int, '', property: :account_list_id
    field :googleAccountId, types.Int, '', property: :google_account_id
    field :calendarIntegration, !types.Boolean, 'DEFAULT false', property: :calendar_integration
    field :calendarIntegrations, types.String, '', property: :calendar_integrations
    field :calendarId, types.String, '', property: :calendar_id
    field :calendarName, types.String, '', property: :calendar_name
    field :emailIntegration, !types.Boolean, 'DEFAULT false', property: :email_integration
    field :contactsIntegration, !types.Boolean, 'DEFAULT false', property: :contacts_integration
    field :contactsLastSynced, types.String, 'timestamp without timezone', property: :contacts_last_synced
    field :createdAt, !types.String, 'The timestamp of the time this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
