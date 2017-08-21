class Task::Filter::ContactInfoAddr < Task::Filter::Base
  def execute_query(tasks, filters)
    # We are plucking ids here because the contact filter already generates an sql statement with several nested subqueries
    # and sending too many of those to postgres can cause unexpected errors and is often slower than breaking things up.
    # Do not change this unless you test the results before pushing to production.

    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::ContactInfoAddr.query(contact_scope(tasks), filters, account_lists).ids })
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::ContactInfoAddr.new(account_lists)'
end
