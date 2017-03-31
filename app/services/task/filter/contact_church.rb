class Task::Filter::ContactChurch < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::Church.query(contact_scope(tasks), filters, account_lists).ids })
  end

  def title
    'Contact Church'
  end

  delegate :custom_options,
           :type,
           to: 'Contact::Filter::Church.new(account_lists)'
end
