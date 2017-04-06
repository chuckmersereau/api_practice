class Contact::Filter::Tags < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.tagged_with(parse_list(filters[:tags]), any: filters[:any_tags].to_s == 'true')
  end
end
