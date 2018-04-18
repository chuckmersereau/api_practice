class Task::Filter::ContactDesignationAccountId < Task::Filter::Base
  def execute_query(tasks, filters)
    filters = clean_contact_filter(filters)
    # We are plucking ids here because the contact filter already generates an sql statement with several nested subqueries
    # and sending too many of those to postgres can cause unexpected errors and is often slower than breaking things up.
    # Do not change this unless you test the results before pushing to production.
    tasks.joins(:contacts)
         .where(contacts:
           {
             id: Contact::Filter::DesignationAccountId.new(account_lists)
                                                      .execute_query(contact_scope(tasks), filters)
                                                      .ids
           })
  end

  def parent
    _('Contact Gift Details')
  end

  def valid_filters?(filters)
    filters[name].present? && !filters[name].is_a?(Hash)
  end

  delegate :custom_options,
           :type,
           :title,
           to: 'Contact::Filter::DesignationAccountId.new(account_lists)'
end
