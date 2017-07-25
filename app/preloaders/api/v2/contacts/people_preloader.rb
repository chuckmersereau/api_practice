class Api::V2::Contacts::PeoplePreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = {
    family_relationships: Api::V2::Contacts::People::RelationshipsPreloader
  }.freeze

  FIELD_ASSOCIATION_MAPPING = {
    avatar: [:primary_picture, :facebook_account],
    parent_contacts: :contacts
  }.freeze
end
