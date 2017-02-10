module Types
  OrganizationAccountType = GraphQL::ObjectType.define do
    name 'OrganizationAccount'
    description 'An Organization Account [TODO - better description]'

    field :id, !types.ID, 'The ID for this Organization Account', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Organization Account was created', property: :created_at
    field :disableDownloads, !types.Boolean, 'Whether or not downloads have been disabled', property: :disable_downloads
    field :lastDownload, types.String, 'The timestamp of the last download', property: :last_download
    field :lockedAt, types.String, 'The timestamp of when the Organization Account was locked', property: :locked_at
    field :organization, !OrganizationType, 'The Organization associated with the Organization Account'
    field :person, !PersonType, 'The Person associated with the Organization Account'
    field :remoteId, types.ID, 'The remote ID for the Organization Account', property: :remote_id
    field :token, types.String, 'The token of the Organization Account'
    field :updatedAt, !types.String, 'The timestamp that the Organization Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Organization Account was last updated', property: :updated_at
    field :username, types.String, 'The username on the Organization Account'
  end
end
