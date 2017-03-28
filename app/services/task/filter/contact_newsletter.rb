class Task::Filter::ContactNewsletter < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::Newsletter.query(contact_scope(tasks), filters, account_lists).ids })
  end
end
