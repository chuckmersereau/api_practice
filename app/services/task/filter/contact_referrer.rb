class Task::Filter::ContactReferrer < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    tasks.includes(contacts: :contact_referrals_to_me)
         .where(contacts: { id: Contact::Filter::Referrer.query(contact_scope(tasks), filters, account_lists).ids })
  end

  def title
    'Contact Referrer'
  end

  delegate :custom_options,
           :parent,
           :type,
           to: 'Contact::Filter::Referrer.new(account_lists)'
end
