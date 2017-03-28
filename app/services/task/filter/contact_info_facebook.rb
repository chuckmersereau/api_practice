class Task::Filter::ContactInfoFacebook < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.includes(contacts: { people: :facebook_accounts })
         .where(contacts: { id: Contact::Filter::ContactInfoFacebook.query(contact_scope(tasks), filters, account_lists).ids })
  end
end
