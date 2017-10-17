class Task::Filter::ContactDonationAmountRecommendation < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    # We are plucking ids here because the contact filter already generates an sql statement with several nested subqueries
    # and sending too many of those to postgres can cause unexpected errors and is often slower than breaking things up.
    # Do not change this unless you test the results before pushing to production.

    tasks.joins(:contacts)
         .where(contacts: { id: Contact::Filter::DonationAmountRecommendation.query(contact_scope(tasks), filters, account_lists).ids })
  end

  def parent
    _('Contact Gift Details')
  end

  delegate :custom_options,
           :type,
           :title,
           to: 'Contact::Filter::DonationAmountRecommendation.new(account_lists)'
end
