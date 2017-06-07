class Api::V2::Contacts::People::RelationshipsPreloader < ApplicationPreloader
  ASSOCIATION_PRELOADER_MAPPING = { related_person: Api::V2::Contacts::PeoplePreloader }.freeze
  FIELD_ASSOCIATION_MAPPING = {}.freeze

  private

  def serializer_class
    FamilyRelationshipSerializer
  end
end
