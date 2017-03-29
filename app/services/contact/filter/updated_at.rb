class Contact::Filter::UpdatedAt < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where(updated_at: filters[:updated_at])
  end
end
