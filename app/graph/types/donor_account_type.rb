module Types
  DonorAccountType = GraphQL::ObjectType.define do
    name 'DonorAccountType'
    description 'A DonorAccountType object'

    connection :contacts, -> { ContactType.connection_type }, "The Donor Account's Contacts"

    field :id, !types.ID, 'The UUID of the Donation', property: :uuid
    field :accountNumber, !types.Float, 'The account number for this Donation Account', property: :account_number
    field :createdAt, !types.String, 'When the DonationAccount was created', property: :created_at
    field :donorType, types.String, 'The type of Donor, ie: "Household", "Church"', property: :donor_type
    field :firstDonationDate, types.String, 'The date in which the Donation Account first donated', property: :first_donation_date
    field :lastDonationDate, types.String, 'The date in which the Donation Account last donated', property: :last_donation_date
    field :organization, OrganizationType, 'The Organization that this Donor Account belongs to'
    field :totalDonations, types.Float, 'The amount of total donations for this Donation Account', property: :total_donations
    field :updatedAt, !types.String, 'The datetime in which the Donation was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Donation was last updated in the database', property: :updated_at
  end
end
