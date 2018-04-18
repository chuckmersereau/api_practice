class Contact::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    Status
    PledgeReceived
    PledgeAmount
    PledgeCurrency
    PledgeFrequency
    PledgeLateBy
    Newsletter
    Referrer
    Likely
    ContactType
    City
    State
    Country
    AddressHistoric
    MetroArea
    Region
    ContactInfoEmail
    ContactInfoPhone
    ContactInfoMobile
    ContactInfoWorkPhone
    ContactInfoAddr
    ContactInfoFacebook
    Church
    RelatedTaskAction
    Appeal
    Timezone
    Locale
    Donation
    DonationAmount
    DonationAmountRange
    DonationDate
    DonationAmountRecommendation
    DesignationAccountId
    TasksAllCompleted
    TaskDueDate
  ).freeze # These filters are displayed in this way on purpose, do not alphabetize them

  FILTERS_TO_HIDE = %w(
    AddressValid
    ExcludeTags
    GaveMoreThanPledgedRange
    Ids
    NameLike
    NoAppeals
    NotIds
    PledgeAmountIncreasedRange
    StartedGivingRange
    StatusValid
    StoppedGivingRange
    Tags
    UpdatedAt
    WildcardSearch
  ).freeze
end
