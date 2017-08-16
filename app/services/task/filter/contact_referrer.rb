class Task::Filter::ContactReferrer < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::Referrer.query(Contact, filters, account_lists))
  end

  def title
    'Contact Referrer'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Referrer.new(account_lists)'
end
