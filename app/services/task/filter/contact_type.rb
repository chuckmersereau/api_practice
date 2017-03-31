class Task::Filter::ContactType < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.includes(contacts: :donor_accounts)
         .where(contacts: { id: Contact::Filter::ContactType.query(contact_scope(tasks), filters, account_lists) })
  end

  def title
    'Contact Type'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::ContactType.new(account_lists)'
end
