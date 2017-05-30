class Contact::Filter::WildcardSearch < Contact::Filter::Base
  def execute_query(contacts, filters)
    @search_term = filters[:wildcard_search].downcase
    @contacts = contacts

    contact_ids  = contact_ids_from_email_addresses_like_search_term
    contact_ids += contact_ids_from_phone_numbers_like_search_term
    contact_ids += contact_ids_from_donor_account_numbers_like_search_term
    contact_ids += contact_ids_from_people_with_first_or_last_name_like_search_term

    contacts_where_name_or_notes_like_search_term_or_with_ids(contact_ids)
  end

  private

  def contact_ids_from_donor_account_numbers_like_search_term
    @contacts
      .joins(:donor_accounts)
      .where('donor_accounts.account_number ilike :search', query_params)
      .ids
  end

  def contact_ids_from_email_addresses_like_search_term
    @contacts
      .joins(people: :email_addresses)
      .where('email_addresses.email ilike :search', query_params)
      .ids
  end

  def contact_ids_from_people_with_first_or_last_name_like_search_term
    @contacts
      .joins(:people)
      .where(sql_condition_to_search_columns_in_parts('people.first_name', 'people.last_name'), query_params(search_term_parts_hash))
      .ids
  end

  def contact_ids_from_phone_numbers_like_search_term
    @contacts
      .joins(people: :phone_numbers)
      .where('phone_numbers.number ilike :search', query_params)
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

  def sql_condition_to_search_columns_in_parts(*columns)
    search_term_parts_hash.keys.collect do |part_key|
      columns.collect do |column|
        "#{column} ilike :#{part_key}"
      end.join(' OR ').prepend('(') + ')'
    end.flatten.join(' AND ').prepend('(') + ')'
  end

  def search_term_parts_hash
    @search_term_parts_hash ||= @search_term.gsub(/[,-]/, ' ').split(' ').each_with_object({}) do |search_term_part, hash|
      hash["search_part_#{hash.size}".to_sym] = "%#{search_term_part}%"
      hash
    end
  end

  def query_params(extra_params = {})
    { search: "%#{@search_term}%" }.merge(extra_params)
  end
end
