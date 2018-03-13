class Contact::Filter::NotIds < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where.not(id: parse_list(filters[:not_ids]))
  end
end
