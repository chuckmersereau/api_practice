class Task::Filter::ContactInfoEmail < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts).merge(Contact::Filter::ContactInfoEmail.query(Contact, filters, account_lists))
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::ContactInfoEmail.new(account_lists)'
end
