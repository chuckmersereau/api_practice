class Person::Filter::EmailAddressValid < Person::Filter::Base
  def execute_query(people, filters)
    self.people = people
    return people unless filters[:email_address_valid] == 'false'
    people_with_invalid_email_addresses
  end

  private

  attr_accessor :people

  def filter_scope
    people.includes(:email_addresses).references(:email_addresses)
  end

  def people_with_invalid_email_addresses
    filter_scope.where('email_addresses.valid_values = :valid OR people.id IN(:people_ids)',
                       valid: false,
                       people_ids: select_person_id_with_duplicate_primary_email_addresses)
  end

  def select_person_id_with_duplicate_primary_email_addresses
    EmailAddress.select(:person_id)
                .where(person_id: people.ids, primary: true)
                .group(:person_id)
                .having('count(*) > 1')
  end
end
