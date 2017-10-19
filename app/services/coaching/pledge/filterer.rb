class Coaching::Pledge::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    Status
  ).freeze

  FILTERS_TO_HIDE = %w(
  ).freeze
end
