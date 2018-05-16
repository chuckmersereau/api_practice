class Task::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    ActivityType
    ContactIds
    ContactChurch
    ContactCity
    ContactCountry
    ContactInfoAddr
    ContactInfoEmail
    ContactInfoMobile
    ContactInfoPhone
    ContactInfoWorkPhone
    ContactLikely
    ContactMetroArea
    ContactNewsletter
    ContactPledgeFrequency
    ContactReferrer
    ContactRegion
    ContactState
    ContactStatus
    ContactTimezone
    ContactType
    ContactDonationAmountRecommendation
    ContactDesignationAccountId
  ).freeze

  FILTERS_TO_HIDE = %w(
    Completed
    DateRange
    ExcludeTags
    Ids
    Overdue
    Starred
    Tags
    UpdatedAt
    WildcardSearch
  ).freeze
end
