class Contact::Filter::Tags < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.tagged_with(filters[:tags].split(',').flatten, any: filters[:any_tags] == 'true')
  end
end
