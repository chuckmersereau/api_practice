class Contact::Filter::AccountList < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      contacts.where(account_list_uuid: filters[:account_list_id])
    end

    def title
      _('Account List')
    end

    def type
      'multiselect'
    end

    def custom_options(account_lists)
      account_lists.collect { |account_list| { name: account_list.name, id: account_list.uuid } }
    end
  end
end
