class FamilyRelationshipSerializer < ApplicationSerializer
  attributes :relationship

  belongs_to :person
  belongs_to :related_person
end
