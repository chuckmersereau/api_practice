class Contact::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    AddressHistoric
    Appeal
    Church
    City
    ContactInfoAddr
    ContactInfoEmail
    ContactInfoFacebook
    ContactInfoMobile
    ContactInfoPhone
    ContactInfoWorkPhone
    ContactType
    Country
    Donation
    DonationAmount
    DonationAmountRange
    DonationDate
    Likely
    Locale
    MetroArea
    Newsletter
    PledgeAmount
    PledgeCurrency
    PledgeFrequencies
    PledgeLateBy
    PledgeReceived
    Referrer
    Region
    RelatedTaskAction
    State
    Status
    TaskDueDate
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
