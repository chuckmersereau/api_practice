class Task::Filter::Starred < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _user)
      tasks.where(starred: filters[:starred])
    end

    def title
      _('Starred')
    end

    def type
      'checkbox'
    end
  end
end
