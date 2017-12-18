class Contact::Filter::WildcardSearch < Contact::Filter::Base
  include ::Concerns::Filter::SearchableInParts

  def execute_query(contacts, filters)
    @search_term = filters[:wildcard_search].downcase
    @contacts = contacts

    contact_ids = contact_ids_from_people_relevant_to_search_term
    contact_ids += contact_ids_from_donor_account_numbers_like_search_term

    contacts_where_name_or_notes_like_search_term_or_with_ids(contact_ids)
  end

  private

  def contact_ids_from_people_relevant_to_search_term
    ContactPerson.where(person: people_relevant_to_search_term).pluck(:contact_id)
  end

  def people_relevant_to_search_term
    Person::Filter::WildcardSearch.query(
      Person.joins(:contact_people).where(contact_people: { contact: @contacts }),
      { wildcard_search: @search_term },
      account_lists
    )
  end

  def contact_ids_from_donor_account_numbers_like_search_term
    @contacts
      .joins(:donor_accounts)
      .where('donor_accounts.account_number ilike :search', query_params)
      .ids
  end

  def contacts_where_name_or_notes_like_search_term_or_with_ids(contact_ids)
    or_conditions = [
      sql_condition_to_search_columns_in_parts('contacts.name'),
      'contacts.notes ilike :search',
      'contacts.id IN (:contact_ids)'
    ].join(' OR ')

    @contacts.where(or_conditions, query_params(search_term_parts_hash.merge(contact_ids: contact_ids)))
  end
end
