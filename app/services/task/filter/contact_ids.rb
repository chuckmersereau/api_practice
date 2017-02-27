class Task::Filter::ContactIds < Task::Filter::Base
  def execute_query(tasks, filters)
    filters[:contact_ids] = filters[:contact_ids].split(',') if filters[:contact_ids].is_a?(String)
    tasks.includes(:contacts).references(:contacts).where(contacts: { uuid: filters[:contact_ids] })
  end

  def title
    _('Contacts')
  end

  def type
    'multiselect'
  end

  def custom_options
    contact_attributes_from_account_lists.collect do |contact|
      { name: contact.name, id: contact.uuid, account_list_id: contact.account_list_uuid }
    end
  end

  def contact_attributes_from_account_lists
    Contact.joins(:account_list).where(account_list: account_lists)
           .order('contacts.name ASC').distinct.select(:uuid, :name, :'account_lists.uuid AS account_list_uuid')
  end
end