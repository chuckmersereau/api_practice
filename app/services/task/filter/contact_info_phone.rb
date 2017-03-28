class Task::Filter::ContactInfoPhone < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::ContactInfoPhone.query(contact_scope(tasks), filters, account_lists).ids })
  end
end
