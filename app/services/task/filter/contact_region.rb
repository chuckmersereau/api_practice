class Task::Filter::ContactRegion < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.includes(contacts: :addresses)
         .where(contacts: { id: Contact::Filter::Region.query(contact_scope(tasks), filters, account_lists).ids })
         .references(:addresses)
  end
end
