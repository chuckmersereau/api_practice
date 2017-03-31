class Task::Filter::ContactStatus < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::Status.query(contact_scope(tasks), filters, account_lists).ids })
  end

  def title
    'Contact Status'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Status.new(account_lists)'
end
