class Contact::Filter::NameLike < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where('name ilike ?', "#{filters[:name_like]}%")
  end
end
