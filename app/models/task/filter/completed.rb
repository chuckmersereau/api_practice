class Task::Filter::Completed < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _account_lists)
      tasks.where(completed: filters[:completed])
    end

    def title
      _('Completed')
    end

    def type
      'checkbox'
    end
  end
end
