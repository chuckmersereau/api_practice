class Api::V2::TasksPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = {
    account_list: Api::V2::AccountListsPreloader,
    contacts: Api::V2::ContactsPreloader,
    email_addresses: Api::V2::Contacts::People::EmailAddressesPreloader,
    people: Api::V2::Contacts::PeoplePreloader,
    phone_numbers: Api::V2::Contacts::People::PhoneNumbersPreloader
  }.freeze

  FIELD_ASSOCIATION_MAPPING = {
    tag_list: :tags,
    location: {
      contacts: [
        :primary_address,
        :addresses
      ]
    }
  }.freeze
end
