class Api::V2::ContactsPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = {
    account_list: Api::V2::AccountListsPreloader,
    appeals: Api::V2::AppealsPreloader,
    contacts: Api::V2::AppealsPreloader,
    contact_referrals_by_me: Api::V2::ContactsPreloader,
    contact_referrals_to_me: Api::V2::ContactsPreloader,
    contacts_referred_by_me: Api::V2::ContactsPreloader,
    contacts_that_referred_me: Api::V2::ContactsPreloader,
    donor_accounts: Api::V2::AccountLists::DonorAccountsPreloader
  }.freeze

  FIELD_ASSOCIATION_MAPPING = {
    avatar: { primary_person: [:primary_picture, :facebook_account] },
    tag_list: :tags
  }.freeze
end
