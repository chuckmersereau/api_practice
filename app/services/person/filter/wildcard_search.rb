class Person::Filter::WildcardSearch < Person::Filter::Base
  include ::Concerns::Filter::SearchableInParts

  def execute_query(people, filters)
    @search_term = filters[:wildcard_search].downcase
    @people = people

    person_ids = person_ids_from_email_addresses_like_search_term
    person_ids += person_ids_from_phone_numbers_like_search_term

    people_from_ids_or_first_or_last_name_like_search_term(person_ids)
  end

  private

  def person_ids_from_email_addresses_like_search_term
    @people
      .joins(:email_addresses)
      .where('email_addresses.email ilike :search', query_params)
      .ids
  end

  def person_ids_from_phone_numbers_like_search_term
    @people
      .joins(:phone_numbers)
      .where('phone_numbers.number ilike :search', query_params)
      .ids
  end

  def people_from_ids_or_first_or_last_name_like_search_term(person_ids)
    or_conditions = [
      sql_condition_to_search_columns_in_parts('people.first_name', 'people.last_name'),
      'people.id IN (:person_ids)'
    ].join(' OR ')

    @people.where(or_conditions, query_params(search_term_parts_hash.merge(person_ids: person_ids)))
  end

  def valid_filters?(filters)
    super && filters[:wildcard_search].is_a?(String)
  end
end
