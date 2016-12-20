class Task::Filter::ContactIds < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _user)
      filters[:contact_ids] = filters[:contact_ids].split(',') if filters[:contact_ids].is_a?(String)
      tasks.includes(:contacts).references(:contacts).where(contacts: { uuid: filters[:contact_ids] })
    end

    def title
      _('Contacts')
    end

    def type
      'multiselect'
    end

    def custom_options(account_list)
      account_list.contacts.collect { |contact| { name: contact.to_s, id: contact.id } }
    end
  end
end
