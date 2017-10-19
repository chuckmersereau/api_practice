class Task::Filter::ContactLikely < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::Likely.query(Contact, filters, account_lists))
  end

  def title
    _('Contact Likely To Give')
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::Likely.new(account_lists)'
end
