class Contact::Filter::NotIds < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where.not(uuid: parse_list(filters[:not_ids]))
  end
end
