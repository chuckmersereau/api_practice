class FamilyRelationshipSerializer < ApplicationSerializer
  attributes :relationship

  belongs_to :related_person
end
