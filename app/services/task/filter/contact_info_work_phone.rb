class Task::Filter::ContactInfoWorkPhone < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts).merge(Contact::Filter::ContactInfoWorkPhone.query(Contact, filters, account_lists))
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::ContactInfoWorkPhone.new(account_lists)'
end
