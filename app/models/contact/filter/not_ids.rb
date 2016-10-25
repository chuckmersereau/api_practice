class Contact::Filter::NotIds < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_list)
      contacts.where('contacts.id not in (?)', filters[:not_ids])
    end
  end
end
