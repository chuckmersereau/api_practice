class AppealContact::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w().freeze

  FILTERS_TO_HIDE = %w(
    PledgedToAppeal
  ).freeze
end
