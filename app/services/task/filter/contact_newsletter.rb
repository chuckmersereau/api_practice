class Task::Filter::ContactNewsletter < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::Newsletter.query(contact_scope(tasks), filters, account_lists).ids })
  end

  def title
    'Contact Newsletter'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Newsletter.new(account_lists)'
end
