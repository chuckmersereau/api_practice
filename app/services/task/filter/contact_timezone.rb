class Task::Filter::ContactTimezone < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts).merge(Contact::Filter::Timezone.query(Contact, filters, account_lists))
  end

  def title
    'Contact Timezone'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Timezone.new(account_lists)'
end
