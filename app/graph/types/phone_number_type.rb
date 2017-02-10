module Types
  PhoneNumberType = GraphQL::ObjectType.define do
    name 'PhoneNumber'
    description 'A Phone Number object'

    field :id, !types.ID, 'The ID for this Phone Number', property: :uuid
    field :countryCode, types.String, 'The country code for the Phone Number', property: :uuid
    field :createdAt, !types.String, 'The timestamp that the Phone Number was created', property: :created_at
    field :historic, types.Boolean, 'Whether or not the Phone Number is still in use'
    field :location, types.String, 'The location of the Phone Number (Home, Work, etc.)'
    field :number, types.String, 'The phone number' do
      resolve -> (obj, args, ctx) { PhoneNumberSerializer.new(obj).number }
    end
    field :primary, types.Boolean, 'Whether or not this is a primary Phone Number'
    field :updatedAt, !types.String, 'The timestamp that the Phone Number was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The timestamp that the Phone Number was last updated', property: :updated_at
  end
end
