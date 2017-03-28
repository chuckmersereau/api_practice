class Task::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    ActivityType
    Completed
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
  ).freeze

  FILTERS_TO_HIDE = %w(
    DateRange
    ExcludeTags
    Ids
    NoDate
    Overdue
    Starred
    Tags
    WildcardSearch
  ).freeze
end
