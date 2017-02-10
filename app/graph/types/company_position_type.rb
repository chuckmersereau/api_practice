module Types
  CompanyPositionType = GraphQL::ObjectType.define do
    name 'CompanyPosition'
    description 'CompanyPosition Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :person, PersonType, '', property: :person
    field :company, !CompanyType, '', property: :company
    field :startDate, types.String, '', property: :start_date
    field :endDate, types.String, '', property: :end_date
    field :position, types.String, '', property: :position
    field :createdAt, !types.String, 'The timestamp this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
