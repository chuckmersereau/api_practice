module Types
  PictureType = GraphQL::ObjectType.define do
    name 'Picture'
    description 'Picture Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :pictureOfId, types.Int, '', property: :picture_of_id
    field :pictureOfType, types.String, '', property: :picture_of_type
    field :image, types.String, '', property: :image
    field :primary, !types.Boolean, 'DEFAULT false', property: :primary
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
