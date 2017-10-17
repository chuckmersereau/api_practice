class Task::Filter::ContactNewsletter < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::Newsletter.query(Contact, filters, account_lists))
  end

  def title
    _('Contact Newsletter')
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Newsletter.new(account_lists)'
end
