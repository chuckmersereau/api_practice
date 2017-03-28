class Task::Filter::ContactLikely < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.includes(:contacts)
         .where(contacts: { id: Contact::Filter::Likely.query(contact_scope(tasks), filters, account_lists).ids })
  end
end
