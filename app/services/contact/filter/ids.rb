class Contact::Filter::Ids < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where(id: parse_list(filters[:ids]))
  end
end
