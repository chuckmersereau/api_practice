class Person::Duplicate < ActiveModelSerializers::Model
  attr_reader :id, :person, :dup_person, :people, :shared_contact
  alias read_attribute_for_serialization send

  def self.find(id)
    people = id.split('~').map do |person_uuid|
      Person.find_by_uuid_or_raise!(person_uuid)
    end

    contact = (people[0].contacts & people[1].contacts).first

    new(person: people.first, dup_person: people.last, shared_contact: contact)
  end

  def all_for_account_list(account_list)
    Person::DuplicatesFinder.new(account_list).find
  end

  def initialize(person:, dup_person:, shared_contact:)
    @shared_contact = shared_contact
    @person = person
    @dup_person = dup_person
    @people = [@person, @dup_person].sort_by(&:id).freeze
    @id = @people.map(&:uuid).join('~').freeze
  end

  def invalidate!
    Person.transaction do
      @person.mark_not_duplicate_of!(@dup_person)
      @dup_person.mark_not_duplicate_of!(@person)
    end
  end

  def shares_an_id_with?(candidate_duplicate)
    id.include?(candidate_duplicate.person.uuid) || id.include?(candidate_duplicate.dup_person.uuid)
  end
end
