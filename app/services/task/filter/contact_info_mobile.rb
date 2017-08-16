class Task::Filter::ContactInfoMobile < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.joins(:contacts).merge(Contact::Filter::ContactInfoMobile.query(Contact, filters, account_lists))
  end

  delegate :custom_options,
           :parent,
           :type,
           :title,
           to: 'Contact::Filter::ContactInfoMobile.new(account_lists)'
end
