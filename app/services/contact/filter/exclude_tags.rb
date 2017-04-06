class Contact::Filter::ExcludeTags < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.tagged_with(parse_list(filters[:exclude_tags]), exclude: true)
  end
end
