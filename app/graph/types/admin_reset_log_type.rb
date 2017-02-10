module Types
  AdminResetLogType = GraphQL::ObjectType.define do
    name 'AdminResetLog'
    description 'AdminResetLog Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :adminResetting, UserType, '', property: :admin_resetting
    field :resettedUser, UserType, '', property: :resetted_user
    field :reason, types.String, '', property: :reason
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
