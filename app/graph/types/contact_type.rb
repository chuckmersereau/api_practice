module Types
  ContactType = GraphQL::ObjectType.define do
    name 'Contact'
    description 'A Contact object'

    connection :addresses, -> { AddressType.connection_type }, 'The Addresses for this Contact'
    connection :appeals, -> { AppealType.connection_type }, 'The Appeals for this Contact'
    connection :contactsReferredByMe, -> { ContactType.connection_type }, 'The Contacts who this Contact has referred', property: :contacts_referred_by_me
    connection :contactsThatReferredMe, -> { ContactType.connection_type }, 'The Contacts who have referred this Contact', property: :contacts_that_referred_me
    connection :donorAccounts, DonorAccountType.connection_type, 'The donor accounts for this Contact', property: :donor_accounts
    connection :people, -> { PersonType.connection_type }, 'The People associated with this Contact'

    field :id, !types.ID, 'The UUID of the Contact', property: :uuid
    field :accountList, AccountListType, 'The parent account list of the Contact', property: :account_list
    field :avatar, !types.String, 'The avatar url of the Contact' do
      resolve -> (obj, args, ctx) {
        ContactSerializer.new(obj).avatar
      }
    end
    field :createdAt, !types.String, 'When the Contact was created', property: :created_at
    field :churchName, !types.String, 'The name of the church of the Contact', property: :church_name
    field :deceased, !types.Boolean, 'Whether or not the Contact is deceased'
    field :envelopeGreeting, !types.String, 'The greeting for this Contact', property: :envelope_greeting
    field :greeting, !types.String, 'The greeting for this Contact'
    field :lastActivity, types.String, 'The date of the last activity for the Contact', property: :last_activity
    field :lastAppointment, types.String, 'The date of the last appointment for the Contact', property: :last_appointment
    field :lastDonation, types.String, 'The date of the last donation for the Contact', property: :last_donation
    field :lastLetter, types.String, 'The date of the last letter for the Contact', property: :last_letter
    field :lastPhoneCall, types.String, 'The date of the last phone call for the Contact', property: :last_phone_call
    field :lastPreCall, types.String, 'The date of the last pre-call for the Contact', property: :last_pre_call
    field :lastThank, types.String, 'The date of the last thank you for the Contact', property: :last_thank
    field :likelyToGive, types.Boolean, 'Whether or not the Contact is likely to give', property: :likely_to_give
    field :locale, types.String, 'The locale of the Contact'
    field :magazine, !types.Boolean, 'Whether or not the Contact receives a magazine'
    field :name, !types.String, 'The name of the Contact'
    field :nextAsk, types.String, 'The date of the next ask for support', property: :next_ask
    field :noAppeals, types.Boolean, 'Whether or not the Contact has no appeals', property: :no_appeals
    field :notes, types.String, 'Notes for this Contact'
    field :notesSavedAt, types.String, 'The datetime of when the notes for this Contact were last saved', property: :notes_saved_at
    field :pledgeAmount, types.Float, 'The amount that the Contact has pledged', property: :pledge_amount
    field :pledgeCurrency, !types.String, "The currency format for the Contact's pledge", property: :pledge_currency
    field :pledgeCurrencySymbol, !types.String, "The symbol that represents the currency format for the Contact's pledge", property: :pledge_currency_symbol
    field :pledgeFrequency, types.Float, 'The frequency in which someone pledges' do
      resolve -> (obj, args, ctx) {
        ContactSerializer.new(obj).pledge_frequency
      }
    end
    field :pledgeReceived, !types.Boolean, 'Whether or not a pledge has been received for this Contact', property: :pledge_received
    field :pledgeStartDate, types.String, "Date in which the Contact's pledge starts", property: :pledge_start_date
    field :sendNewsletter, types.String, 'The type of newsletter to be sent to this Contact. Physical, Email, or Both', property: :send_newsletter
    field :squareAvatar, !types.String, "A url for the Contact's avatar - but in a square format" do
      resolve -> (obj, args, ctx) {
        ContactSerializer.new(obj).square_avatar
      }
    end
    field :status, types.String, 'The partner status of the Contact'
    field :tagList, types[types.String], 'A list of tags', property: :tag_list
    field :timezone, types.String, "The Contact's timezone name"
    field :totalDonations, types.Float, 'The total amount of donations given by this Contact', property: :total_donations
    field :uncompletedTasksCount, !types.Int, 'The number of uncompleted tasks for this Contact', property: :uncompleted_tasks_count
    field :updatedAt, !types.String, 'The time in which the Contact was last updated', property: :updated_at
    field :updatedInDbAt, !types.String, 'The time in which the Contact was last updated in the database', property: :updated_at
  end
end
