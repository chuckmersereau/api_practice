module Types
  GoogleContactType = GraphQL::ObjectType.define do
    name 'GoogleContact'
    description 'GoogleContact Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :remoteId, types.String, '', property: :remote_id
    field :person, PersonType, '', property: :person
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :pictureEtag, types.String, '', property: :picture_etag
    field :picture, PictureType, '', property: :picture
    field :googleAccount, GoogleAccountType, '', property: :google_account
    field :lastSynced, types.String, 'timestamp without timezone', property: :last_synced
    field :lastEtag, types.String, '', property: :last_etag
    field :lastData, types.String, '', property: :last_data
    field :contact, ContactType, '', property: :contact
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
