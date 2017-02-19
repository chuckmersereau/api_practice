class Contact::Filter::StatusValid < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where(status_valid: filters[:status_valid] == 'true')
  end
end
