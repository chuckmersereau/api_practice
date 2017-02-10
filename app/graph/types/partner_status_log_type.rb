module Types
  PartnerStatusLogType = GraphQL::ObjectType.define do
    name 'PartnerStatusLog'
    description 'PartnerStatusLog Object'
    field :_appId, !types.ID, 'The application ID', property: :id
    field :contact, ContactType, '', property: :contact
    field :recordedOn, !types.String, '', property: :recorded_on
    field :status, types.String, '', property: :status
    field :pledgeAmount, types.Int, '', property: :pledge_amount
    field :pledgeFrequency, types.Int, '', property: :pledge_frequency
    field :pledgeReceived, types.Boolean, '', property: :pledge_received
    field :pledgeStartDate, types.String, '', property: :pledge_start_date
    field :createdAt, !types.String, 'The timestamp of the time this was created', property: :created_at
    field :updatedAt, !types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :id, !types.ID, 'The UUID', property: :uuid
  end
end
