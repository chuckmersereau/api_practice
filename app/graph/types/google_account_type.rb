module Types
  GoogleAccountType = GraphQL::ObjectType.define do
    name 'GoogleAccount'
    description 'A Google Account object'

    field :id, !types.ID, 'The ID for this Google Account', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Google Account was created', property: :created_at
    field :email, !types.String, 'The email address on the Google Account'
    field :expiresAt, types.String, 'The timestamp that the Google Account expires [TODO]', property: :expires_at
    field :lastDownload, types.String, 'The timestamp of the last download from the Google Account [TODO]', property: :last_download
    field :lastEmailSync, types.String, 'The timestamp of the last email sync of the Google Account', property: :last_email_sync
    field :primary, types.Boolean, 'Whether or not the Google Account is primary [TODO]'
    field :refreshToken, types.String, 'The refresh token of the Google Account [TODO]', property: :refresh_token
    field :remoteId, types.ID, 'The ID given by Google for the Google Account', property: :remote_id
    field :token, types.String, 'The token for the Google Account'
    field :updatedAt, !types.String, 'The timestamp that the Google Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Google Account was last updated', property: :updated_at
  end
end
