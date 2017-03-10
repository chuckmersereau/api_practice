class Contact::Filter::ExcludeTags < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.tagged_with(filters[:exclude_tags].split(',').map(&:strip), exclude: true)
  end
end
