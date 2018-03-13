class Task::Filter::ContactIds < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts).where(contacts: { id: parse_list(filters[:contact_ids]) })
  end

  def title
    _('Contacts')
  end

  def type
    'multiselect'
  end

  def custom_options
    contact_attributes_from_account_lists.collect do |contact|
      { name: contact.name, id: contact.id, account_list_id: contact.account_list_id }
    end
  end

  def contact_attributes_from_account_lists
    Contact.joins(:account_list).where(account_list: account_lists)
           .order('contacts.name ASC').distinct.select('contacts.id, contacts.name, account_lists.id AS account_list_id')
  end
end
