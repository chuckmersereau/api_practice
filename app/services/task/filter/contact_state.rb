class Task::Filter::ContactState < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.includes(contacts: :addresses)
         .where(contacts: { id: Contact::Filter::State.query(contact_scope(tasks), filters, account_lists).ids })
         .references(:addresses)
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::State.new(account_lists)'
end
