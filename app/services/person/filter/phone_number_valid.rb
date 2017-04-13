class Person::Filter::PhoneNumberValid < Person::Filter::Base
  def execute_query(people, filters)
    self.people = people
    return people unless filters[:phone_number_valid] == 'false'

    # Fetching a second time to allow loading of both valid and invalid phone numbers.
    # Without this, it'll return people, but only invalid phone numbers will be included.
    Person.where(id: people_with_invalid_phone_numbers.ids)
  end

  private

  attr_accessor :people

  def filter_scope
    people.includes(:phone_numbers).references(:phone_numbers)
  end

  def people_with_invalid_phone_numbers
    filter_scope.where('phone_numbers.valid_values = :valid OR people.id IN(:people_ids)',
                       valid: false,
                       people_ids: select_person_id_with_duplicate_primary_phone_numbers)
  end

  def select_person_id_with_duplicate_primary_phone_numbers
    PhoneNumber.select(:person_id)
               .where(person_id: people.ids, primary: true)
               .group(:person_id)
               .having('count(*) > 1')
  end
end
