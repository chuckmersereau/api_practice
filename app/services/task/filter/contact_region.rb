class Task::Filter::ContactRegion < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::Region.query(Contact, filters, account_lists))
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::Region.new(account_lists)'
end
