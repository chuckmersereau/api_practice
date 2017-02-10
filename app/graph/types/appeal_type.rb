module Types
  AppealType = GraphQL::ObjectType.define do
    name 'Appeal'
    description 'An Appeal object'

    connection :contacts, -> { ContactType.connection_type }, 'The Contacts associated with this Appeal'
    connection :donations, -> { DonationType.connection_type }, 'The donations given to this Appeal'

    field :id, !types.ID, 'The UUID of the Appeal', property: :uuid
    field :accountList, AccountListType, 'The Account List for this Appeal', property: :account_list
    field :amount, types.Float, 'The amount requested for this Appeal'
    field :createdAt, !types.String, 'The datetime when the Appeal was created', property: :created_at
    field :currencies, types[types.String], 'The currencies of the donations for this Appeal'
    field :description, types.String, 'The description for this Appeal'
    field :endDate, types.String, 'The date in which this Appeal ends', property: :end_date
    field :name, types.String, 'The name of the Appeal'
    field :totalCurrency, types.String, "The type of currency for the Appeal's donations to be converted to"
    field :updatedAt, !types.String, 'The datetime in which the Appeal was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Appeal was last updated in the database', property: :updated_at
  end
end
