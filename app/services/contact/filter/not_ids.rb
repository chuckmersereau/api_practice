class Contact::Filter::NotIds < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where('contacts.uuid not in (?)', filters[:not_ids])
  end
end
