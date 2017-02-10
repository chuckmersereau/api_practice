module Types
  AdminImpersonationLogType = GraphQL::ObjectType.define do
    name 'AdminImpersonationLog'
    description 'AdminImpersonationLog Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :reason, !types.String, '', property: :reason
    field :impersonator, UserType, '', property: :impersonator
    field :impersonated, UserType, '', property: :impersonated
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
