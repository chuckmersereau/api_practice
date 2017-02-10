module Types
  DonationType = GraphQL::ObjectType.define do
    name 'Donation'
    description 'A Donation object'

    field :id, !types.ID, 'The UUID of the Donation', property: :uuid
    field :amount, !types.Float, 'The Donation amount'
    field :appeal, AppealType, 'The Appeal for this Donation'
    field :appealAmount, types.Float, "The total amount on the Donation's Appeal", property: :appeal_amount
    field :channel, types.String, 'The channel in which the Donation was made'
    field :contact, ContactType, 'The Contact associated with this Donation' do
      resolve -> (donation, args, ctx) {
        account_list_id = ctx[:account_list_id]
        return unless account_list_id

        donation
          .donor_account
          .contacts
          .where(account_list_id: account_list_id)
          .first
      }
    end
    field :createdAt, !types.String, 'When the Donation was created', property: :created_at
    field :currency, types.String, 'The currency of the Donation, ex: "USD"'
    field :designationAccount, DesignationAccountType, 'The DesignationAccount for this Donation', property: :designation_account
    field :donorAccount, DonorAccountType, 'The Donor Account for this Donation', property: :donor_account
    field :donationDate, !types.String, 'The date of the Donation', property: :donation_date
    field :memo, types.String, 'A memo for the purpose of the Donation'
    field :motivation, types.String, 'TODO'
    field :paymentMethod, types.String, 'The method in which the Donation was made, ex: "CASH", "BANK_TRANS"', property: :payment_method
    field :paymentType, types.String, 'The type of payment for the Donation', property: :payment_type
    field :remoteId, types.String, 'A remote identifier for the Donation', property: :remote_id
    field :tenderedAmount, types.Float, 'The tendered amount of the Donation', property: :tendered_amount
    field :tenderedCurrency, types.String, 'The tendered currency of the Donation', property: :tendered_currency
    field :updatedAt, !types.String, 'The datetime in which the Donation was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The datetime in which the Donation was last updated in the database', property: :updated_at
  end
end
