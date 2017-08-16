class Task::Filter::ContactPledgeFrequency < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::PledgeFrequency.query(Contact, filters, account_lists))
  end

  def title
    'Contact Commitment Frequency'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::PledgeFrequency.new(account_lists)'
end
