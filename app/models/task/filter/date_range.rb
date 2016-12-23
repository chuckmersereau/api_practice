class Task::Filter::DateRange < Task::Filter::Base
  class << self
    protected

    def execute_query(tasks, filters, _account_lists)
      case filters[:date_range]
      when 'last_month'
        tasks.where('completed_at > ?', 1.month.ago)
      when 'last_year'
        tasks.where('completed_at > ?', 1.year.ago)
      when 'last_two_years'
        tasks.where('completed_at > ?', 2.years.ago)
      when 'last_week'
        tasks.where('completed_at > ?', 1.week.ago)
      when 'overdue'
        tasks.overdue
      when 'today'
        tasks.today
      when 'tomorrow'
        tasks.tomorrow
      when 'future'
        tasks.future
      when 'upcoming'
        tasks.upcoming
      end
    end

    def title
      _('Date Range')
    end

    def type
      'multiselect'
    end
  end
end
