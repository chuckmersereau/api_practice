class Task::Filter::Overdue < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _user)
      return tasks.overdue if filters[:overdue].to_s == 'true'
      tasks.where('start_at > ?', Time.current.beginning_of_day)
    end

    def title
      _('Overdue')
    end

    def type
      'checkbox'
    end
  end
end
