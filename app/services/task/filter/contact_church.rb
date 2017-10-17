class Task::Filter::ContactChurch < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::Church.query(Contact, filters, account_lists))
  end

  def title
    _('Contact Church')
  end

  delegate :custom_options,
           :type,
           to: 'Contact::Filter::Church.new(account_lists)'
end
