class Person::Filterer < ApplicationFilterer
  FILTERS_TO_HIDE = %w(
    EmailAddressValid
    PhoneNumberValid
    UpdatedAt
    WildcardSearch
  ).freeze
end
