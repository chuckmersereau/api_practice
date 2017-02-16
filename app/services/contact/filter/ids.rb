class Contact::Filter::Ids < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where('contacts.uuid' => filters[:ids].split(','))
  end
end
