module Types
  KeyAccountType = GraphQL::ObjectType.define do
    name 'KeyAccount'
    description 'A Key Account object'

    field :id, !types.ID, 'The ID for this Key Account', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Key Account was created', property: :created_at
    field :email, !types.String, 'The email address on the Key Account'
    field :firstName, !types.String, 'The first name on the Ket Account', property: :first_name
    field :lastDownload, types.String, 'The timestamp of the last download from the Key Account [TODO]', property: :last_download
    field :lastName, !types.String, 'The last name on the Key Account', property: :last_name
    field :primary, types.Boolean, 'Whether or not the Key Account is primary [TODO]'
    field :remoteId, types.ID, 'The ID given by Key for the Key Account', property: :remote_id
    field :updatedAt, !types.String, 'The timestamp that the Key Account was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Key Account was last updated', property: :updated_at
  end
end
