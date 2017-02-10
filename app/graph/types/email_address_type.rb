module Types
  EmailAddressType = GraphQL::ObjectType.define do
    name 'EmailAddress'
    description 'An Email Address object'

    field :id, !types.ID, 'The UUID of the Email Address', property: :uuid
    field :createdAt, !types.String, 'The datetime of when this Email Address was created', property: :created_at
    field :email, !types.String, 'The email for the Email'
    field :historic, types.Boolean, 'Whether or not this Email Address is no longer being used'
    field :location, types.String, 'The location for this Email Address, ie: Work, Home, Cell'
    field :primary, types.Boolean, 'Whether or not this Email Addres is the primary'
    field :updatedAt, !types.String, 'The datetime of when this Email Address last updated', property: :created_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Email Address was last updated in the database', property: :updated_at
  end
end
