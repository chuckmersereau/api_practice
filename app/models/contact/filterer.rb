class Contact::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    Status
    Newsletter
    PledgeReceived
    PledgeFrequencies
    PledgeAmount
    PledgeCurrency
    Donation
    DonationDate
    DonationAmountRange
    DonationAmount
    RelatedTaskAction
    TaskDueDate
    Referrer
    City
    State
    Region
    Country
    MetroArea
    AddressHistoric
    ContactInfoEmail
    ContactInfoPhone
    ContactInfoMobile
    ContactInfoWorkPhone
    ContactInfoAddr
    ContactInfoFacebook
    Locale
    Church
    Likely
    ContactType
    Appeal
    Timezone
  ).freeze

  FILTERS_TO_HIDE = %w(
    Ids
    Name
    NotIds
    Tags
    WildcardSearch
  ).freeze
end
