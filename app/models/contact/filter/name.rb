class Contact::Filter::Name < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      contacts.where('lower(contacts.name) like ?', "%#{filters[:name].downcase}%")
    end
  end
end
