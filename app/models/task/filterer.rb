class Task::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    ContactIds
    Completed
    ActivityType
  ).freeze

  FILTERS_TO_HIDE = %w(
    Overdue
    Tags
    Starred
    NoDate
    DateRange
  ).freeze
end
