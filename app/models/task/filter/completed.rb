class Task::Filter::Completed < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _user)
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
