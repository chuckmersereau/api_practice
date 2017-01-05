class Task::Filter::DateRange < Task::Filter::Base
  def execute_query(tasks, filters)
    case filters[:date_range]
    when 'last_week'
      tasks.where('completed_at <= ? and completed_at > ?', 1.week.ago, 2.weeks.ago)
    when 'last_month'
      tasks.where('completed_at <= ? AND completed_at > ?', 1.month.ago, 2.months.ago)
    when 'last_year'
      tasks.where('completed_at <= ? AND completed_at > ?', 1.year.ago, 2.years.ago)
    when 'last_two_years'
      tasks.where('completed_at <= ? AND completed_at > ?', 2.years.ago, 3.years.ago)
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
    'radio'
  end
end
