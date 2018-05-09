class ContactPerson < ApplicationRecord
  include HasPrimary
  @@primary_scope = :contact

  belongs_to :contact, touch: true
  belongs_to :person

  after_commit :delete_orphaned_person, on: :destroy
  before_create :set_primary_contact

  validates :person, presence: true

  # Scopes
  scope :find_ids_with_search_term, -> (search_term) { where(person: search_term) }

  private

  def delete_orphaned_person
    # See if there is any other contact_person with the same person id
    return if ContactPerson.where(person_id: person_id).where('id <> ?', id).any?
    # if there isn't, delete the associated person
    person&.destroy
  end

  def set_primary_contact
    self.primary = true if contact && !contact.primary_person
  end
end
