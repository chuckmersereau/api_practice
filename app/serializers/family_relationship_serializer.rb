class FamilyRelationshipSerializer < ApplicationSerializer
  attributes :person_id,
             :related_person_id,
             :relationship
end
