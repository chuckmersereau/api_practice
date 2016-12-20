class Task::Filter::Tags < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _user)
      tasks.tagged_with(filters[:tags])
    end

    def title
      _('Tags')
    end

    def type
      'multiselect'
    end
  end
end
