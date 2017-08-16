class Task::Filter::ContactMetroArea < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::MetroArea.query(Contact, filters, account_lists))
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::MetroArea.new(account_lists)'
end
