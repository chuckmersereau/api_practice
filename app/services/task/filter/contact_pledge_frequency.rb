class Task::Filter::ContactPledgeFrequency < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::PledgeFrequency.query(contact_scope(tasks), filters, account_lists).ids })
  end

  def title
    'Contact Commitment Frequency'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::PledgeFrequency.new(account_lists)'
end
