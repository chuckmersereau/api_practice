class Contact::Filter::WildcardSearch < Contact::Filter::Base
  def execute_query(contacts, filters)
    search_term = filters[:wildcard_search].downcase

    contact_ids  = contact_ids_from_email_addresses_like_search_term(contacts, search_term)
    contact_ids += contact_ids_from_phone_numbers_like_search_term(contacts, search_term)
    contact_ids += contact_ids_from_donor_account_numbers_like_search_term(contacts, search_term)
    contact_ids += contact_ids_from_people_with_first_or_last_name_like_search_term(contacts, search_term)

    contacts_where_name_or_notes_like_search_term_or_with_ids(contacts, search_term, contact_ids)
  end

  private

  def contact_ids_from_donor_account_numbers_like_search_term(contacts, search_term)
    contacts
      .joins(:donor_accounts)
      .where('lower(donor_accounts.account_number) like :search', search: "#{search_term}%")
      .ids
  end

  def contact_ids_from_email_addresses_like_search_term(contacts, search_term)
    contacts
      .joins(people: :email_addresses)
      .where('lower(email_addresses.email) like :search', search: "#{search_term}%")
      .ids
  end

  def contact_ids_from_people_with_first_or_last_name_like_search_term(contacts, search_term)
    contacts
      .joins(:people)
      .where('lower(people.first_name) like :search OR lower(people.last_name) like :search', search: "#{search_term}%")
      .ids
  end

  def contact_ids_from_phone_numbers_like_search_term(contacts, search_term)
    contacts
      .joins(people: :phone_numbers)
      .where('lower(phone_numbers.number) like :search', search: "%#{search_term}%")
      .ids
  end

  def contacts_where_name_or_notes_like_search_term_or_with_ids(contacts, search_term, contact_ids)
    contacts
      .where(
        'lower(contacts.name) like :search OR lower(contacts.notes) like :search OR contacts.id IN (:contact_ids)',
        search: "%#{search_term}%",
        contact_ids: contact_ids
      )
  end
end
