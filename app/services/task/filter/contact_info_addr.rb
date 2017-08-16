class Task::Filter::ContactInfoAddr < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts).merge(Contact::Filter::ContactInfoAddr.query(Contact, filters, account_lists))
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::ContactInfoAddr.new(account_lists)'
end
