module Types
  ConstantsLookupType = GraphQL::ObjectType.define do
    name 'ConstantsLookup'
    description 'An object of Constants'

    field :activities, types[types.String], 'Activities Constants'
    field :assignable_likely_to_give, types[types.String], 'Assignable Likely to Give'
    field :assignable_send_newsletter, types[types.String], 'Assignable Send Newsletter'
    field :pledge_currencies, types[types[types.String]], 'Pledge Currencies (JSON)'
    field :pledge_frequencies, types[types[types.String]], 'Pledge Frequencies (JSON)'
    field :statuses, types[types.String], 'Statuses'
    field :locales, types[types[types.String]], 'Locales (JSON)'
    field :notifications, types[types[types.String]], 'Notifications (JSON)'
    field :organizations, types[types[types.String]], 'Organizations (JSON)'
  end
end
