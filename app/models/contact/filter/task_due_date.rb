class Contact::Filter::TaskDueDate < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _user)
      params = daterange_params(filters[:task_due_date])
      contacts = contacts.includes(:activities).references(:activities)
      contacts = contacts.where('activities.start_at >= ?', params[:start]) if params[:start]
      contacts = contacts.where('activities.start_at <= ?', params[:end]) if params[:end]
      contacts
    end

    def title
      _('Due Date')
    end

    def parent
      _('Tasks')
    end

    def type
      'daterange'
    end

    def custom_options(_account_list)
      [
        { name: _('Yesterday'), start: 1.day.ago.beginning_of_day + 1.hour, end: 1.day.ago.end_of_day },
        { name: _('Today'), start: Time.current.beginning_of_day + 1.hour, end: Time.current.end_of_day },
        { name: _('Tomorrow'), start: 1.day.from_now.beginning_of_day + 1.hour, end: 1.day.from_now.end_of_day },
        { name: _('This Week'), start: Time.current.beginning_of_week, end: Time.current.end_of_week - 1.day },
        { name: _('Next Week'), start: 1.week.from_now.beginning_of_week, end: 1.week.from_now.end_of_week - 1.day },
        { name: _('This Month'), start: Time.current.beginning_of_month + 1.hour, end: Time.current.end_of_month },
        { name: _('Next Month'), start: 1.month.from_now.beginning_of_month + 1.hour, end: 1.month.from_now.end_of_month }
      ]
    end

    def valid_filters?(filters)
      super && daterange_params(filters[:task_due_date]).present?
    end
  end
end
