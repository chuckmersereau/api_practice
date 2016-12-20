class Contact::Filter::Ids < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      contacts.where('contacts.id' => filters[:ids].split(','))
    end
  end
end
