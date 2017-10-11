class FamilyRelationship < ApplicationRecord
  belongs_to :person
  belongs_to :related_person, class_name: 'Person'

  validates :related_person_id, :relationship, presence: true

  PERMITTED_ATTRIBUTES = [:created_at,
                          :person_id,
                          :overwrite,
                          :relationship,
                          :related_person_id,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  def self.add_for_person(person, attributes)
    fr = person.family_relationships.find_by(related_person_id: attributes[:related_person_id])
    return fr if fr

    new_or_create = person.new_record? ? :new : :create
    attributes = attributes.except(:_destroy)
    person.family_relationships.send(new_or_create, attributes)
  end
end
