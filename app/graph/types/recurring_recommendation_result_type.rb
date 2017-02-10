module Types
  RecurringRecommendationResultType = GraphQL::ObjectType.define do
    name 'RecurringRecommendationResult'
    description 'RecurringRecommendationResult Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :accountList, AccountListType, 'The parent account list', property: :account_list
    field :contact, ContactType, '', property: :contact
    field :result, !types.String, '', property: :result
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
