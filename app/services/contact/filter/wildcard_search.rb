class Contact::Filter::WildcardSearch < Contact::Filter::Base
  def execute_query(contacts, filters)
    if filters[:wildcard_search] != 'null'
      if filters[:wildcard_search].include?(',')
        last_name, first_name = filters[:wildcard_search].split(',')
      else
        first_name, last_name = filters[:wildcard_search].split
      end

      if first_name.present? && last_name.present?
        first_name = first_name.downcase.strip
        last_name = last_name.downcase.strip
        person_search = ' OR (lower(people.first_name) like :first_name AND lower(people.last_name) like :last_name)'
      else
        person_search = ''
      end

      search_term = filters[:wildcard_search].downcase

      contacts = contacts.where(
        'lower(email_addresses.email) like :general_search '\
          'OR lower(contacts.name) like :name_search '\
          'OR lower(donor_accounts.account_number) like :general_search '\
          'OR lower(phone_numbers.number) like :general_search' + person_search,
        name_search: "#{search_term}%", general_search: "%#{search_term}%", first_name: first_name, last_name: last_name
      )
                         .includes(people: :email_addresses)
                         .references('email_addresses')
                         .includes(:donor_accounts)
                         .references('donor_accounts')
                         .includes(people: :phone_numbers)
                         .references('phone_numbers')
    end

    contacts
  end
end
