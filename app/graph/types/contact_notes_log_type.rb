module Types
  ContactNotesLogType = GraphQL::ObjectType.define do
    name 'ContactNotesLog'
    description 'ContactNotesLog Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :contact, ContactType, '', property: :contact
    field :recordedOn, types.String, '', property: :recorded_on
    field :notes, types.String, '', property: :notes
    field :createdAt, !types.String, 'The timestamp of the time this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
