module Types
  CurrencyAliasType = GraphQL::ObjectType.define do
    name 'CurrencyAlias'
    description 'CurrencyAlias Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :aliasCode, !types.String, '', property: :alias_code
    field :rateApiCode, !types.String, '', property: :rate_api_code
    field :ratio, !types.Int, '', property: :ratio
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
