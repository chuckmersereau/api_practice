class Contact::Filter::Ids < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where(uuid: parse_list(filters[:ids]))
  end
end
