class Person::Filterer < ApplicationFilterer
  FILTERS_TO_HIDE = %w(
    Deceased
    EmailAddressValid
    PhoneNumberValid
    UpdatedAt
    WildcardSearch
  ).freeze
end
