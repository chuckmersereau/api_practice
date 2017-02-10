module Types
  CurrencyRateType = GraphQL::ObjectType.define do
    name 'CurrencyRate'
    description 'CurrencyRate Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :exchangedOn, !types.String, '', property: :exchanged_on
    field :code, !types.String, '', property: :code
    field :rate, !types.Float, '', property: :rate
    field :source, !types.String, '', property: :source
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
