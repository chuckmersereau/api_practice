class Task::Filter::ContactStatus < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::Status.query(Contact, filters, account_lists))
  end

  def title
    _('Contact Status')
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Status.new(account_lists)'
end
