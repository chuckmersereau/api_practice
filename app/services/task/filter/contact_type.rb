class Task::Filter::ContactType < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts).merge(Contact::Filter::ContactType.query(Contact, filters, account_lists))
  end

  def title
    'Contact Type'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::ContactType.new(account_lists)'
end
