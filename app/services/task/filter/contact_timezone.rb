class Task::Filter::ContactTimezone < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::Timezone.query(contact_scope(tasks), filters, account_lists).ids })
  end

  def title
    'Contact Timezone'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Timezone.new(account_lists)'
end
