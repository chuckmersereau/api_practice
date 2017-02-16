class Contact::Filter::ExcludeTags < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.tagged_with(filters[:exclude_tags].split(',').flatten, exclude: true)
  end
end
