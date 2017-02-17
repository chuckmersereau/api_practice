class Task::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    ActivityType
    Completed
    ContactIds
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
