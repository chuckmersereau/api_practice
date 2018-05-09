class Contact::Filter::WildcardSearch < Contact::Filter::Base
  include ::Concerns::Filter::SearchableInParts

  def execute_query(contacts, filters)
    @search_term    = filters[:wildcard_search].downcase
    @contacts       = contacts
    contacts_where_name_like_search_term_or_with_ids
  end

  private

  def contacts_where_name_like_search_term_or_with_ids
    or_conditions = build_sql_conditions_for_search

    @contacts.where(
      or_conditions.join(' OR '),
      query_params(search_term_parts_hash.merge(contact_ids: gather_contact_ids))
    )
  end

  def valid_filters?(filters)
    super && filters[:wildcard_search].is_a?(String)
  end

  def gather_contact_ids
    (contact_ids_from_people_relevant_to_search_term || []) +
      (contact_ids_from_donor_account_numbers_like_search_term || [])
  end

  def build_sql_conditions_for_search
    [
      sql_condition_to_search_columns_in_parts('contacts.name'),
      'contacts.id IN (:contact_ids)'
    ]
  end

  def contact_ids_from_people_relevant_to_search_term
    ContactPerson.find_ids_with_search_term(
      people_relevant_to_search_term
    ).pluck(:contact_id)
  end

  def people_relevant_to_search_term
    Person::Filter::WildcardSearch.query(
      Person.search_for_contacts(@contacts),
      { wildcard_search: @search_term },
      account_lists
    )
  end

  def contact_ids_from_donor_account_numbers_like_search_term
    @contacts.search_donor_account_numbers(@search_term).ids
  end
end
