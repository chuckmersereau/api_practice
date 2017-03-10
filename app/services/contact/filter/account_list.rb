class Contact::Filter::AccountList < Contact::Filter::Base
  def execute_query(contacts, filters)
    contacts.where(account_list_uuid: filters[:account_list_id].split(',').map(&:strip))
  end

  def title
    _('Account List')
  end

  def type
    'multiselect'
  end

  def custom_options
    account_lists.collect { |account_list| { name: account_list.name, id: account_list.uuid } }
  end
end
