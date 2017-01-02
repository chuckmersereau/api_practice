class Person::Duplicate < ActiveModelSerializers::Model
  attr_reader :id, :person, :dup_person, :people, :shared_contact

  def self.find(id)
    people = id.split('|').map do |person_id|
      Person.find(person_id)
    end
    new(*people)
  end

  def all_for_account_list(account_list)
    Person::DuplicatesFinder.new(account_list).find
  end

  def initialize(person:, dup_person:, shared_contact:)
    @shared_contact = shared_contact
    @person = person
    @dup_person = dup_person
    @people = [@person, @dup_person].sort_by(&:id).freeze
    @id = @people.map(&:id).join('|').freeze
  end
end
