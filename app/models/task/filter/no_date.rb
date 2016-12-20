class Task::Filter::NoDate < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _user)
      tasks.where(no_date: filters[:no_date])
    end

    def title
      _('No Date')
    end

    def type
      'checkbox'
    end
  end
end
