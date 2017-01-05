class Contact::Filter::Name < Contact::Filter::Base
  def execute_query(contacts, filters, _account_lists)
    contacts.where('lower(contacts.name) like ?', "%#{filters[:name].downcase}%")
  end
end
