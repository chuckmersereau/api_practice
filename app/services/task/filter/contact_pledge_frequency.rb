class Task::Filter::ContactPledgeFrequency < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::PledgeFrequency.query(Contact, filters, account_lists))
  end

  def parent
    _('Contact Commitment Details')
  end

  delegate :custom_options,
           :title,
           :type,
           to: 'Contact::Filter::PledgeFrequency.new(account_lists)'
end
