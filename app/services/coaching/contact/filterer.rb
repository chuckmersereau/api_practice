class Coaching::Contact::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(
    Pledge
  ).freeze

  FILTERS_TO_HIDE = %w(
  ).freeze
end
