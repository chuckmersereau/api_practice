class Contact::Filter::Ids < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where('contacts.id' => filters[:ids].split(','))
  end
end
