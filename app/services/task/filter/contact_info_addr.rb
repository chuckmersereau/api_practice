class Task::Filter::ContactInfoAddr < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::ContactInfoAddr.query(contact_scope(tasks), filters, account_lists).ids })
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::ContactInfoAddr.new(account_lists)'
end
