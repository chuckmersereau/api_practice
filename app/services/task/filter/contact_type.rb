class Task::Filter::ContactType < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.includes(contacts: :donor_accounts)
         .where(contacts: { id: Contact::Filter::ContactType.query(contact_scope(tasks), filters, account_lists) })
  end
end
