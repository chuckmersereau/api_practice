class Contact::Filter::Ids < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      contacts.where('contacts.id' => filters[:ids].split(','))
    end
  end
end
