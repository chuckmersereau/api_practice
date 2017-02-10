module Types
  PrayerLetterAccountType = GraphQL::ObjectType.define do
    name 'PrayerLetterAccount'
    description 'A Prayer Letter Account object'

    field :id, !types.ID, 'The UUID of the Organization', property: :uuid
    field :createdAt, !types.String, 'When the Organization was created', property: :created_at
    field :token, !types.String, 'The token for the Prayer Letter Account'
    field :updatedAt, !types.String, 'The datetime in which the Organization was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Organization was last updated in the database', property: :updated_at
  end
end
