class Api::V2::ContactsPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = {
    account_list: Api::V2::AccountListsPreloader,
    appeals: Api::V2::AppealsPreloader,
    contact_referrals_by_me: self,
    contact_referrals_to_me: self,
    contacts_referred_by_me: self,
    contacts_that_referred_me: self,
    donor_accounts: Api::V2::AccountLists::DonorAccountsPreloader
  }.freeze

  FIELD_ASSOCIATION_MAPPING = {
    avatar: { primary_person: [:primary_picture, :facebook_account, primary_email_address: :google_plus_account] },
    tag_list: :tags
  }.freeze
end
