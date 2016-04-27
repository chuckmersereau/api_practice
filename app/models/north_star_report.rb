class NorthStarReport
  include ActiveRecord::Sanitization

  def initialize(end_date: Time.zone.today, weeks: 20)
    @end_date = end_date
    @weeks = weeks
  end

  def weeks
    start_date = (@end_date - @weeks.weeks).beginning_of_week
    end_date = (@end_date - 1.week).end_of_week
    inner_query = AccountList.select("date_trunc('week', activities.completed_at) AS week, "\
                                     'count(DISTINCT account_lists.id) AS users')
                             .where(activities: { completed_at: start_date..end_date })
                             .group('week')
                             .joins(:activities).to_sql
    format AccountList.connection.execute(inner_query).to_a
  end

  def months
    start_date = (@end_date - @weeks.months).beginning_of_month
    inner_query = AccountList.select("date_trunc('month', activities.completed_at) AS month, "\
                                     'count(DISTINCT account_lists.id) AS users')
                             .where(activities: { completed_at: start_date..@end_date })
                             .group('month')
                             .joins(:activities).to_sql
    format AccountList.connection.execute(inner_query).to_a
  end

  def weeks_with_history
    current = weeks
    old_end_date = @end_date
    @end_date -= 52.weeks
    historic = weeks
    @end_date = old_end_date
    current.each_with_index { |row, i| row['old'] = historic.dig(i, 'users') }
  end

  private

  def format(data_array)
    data_array.each do |row|
      row['week'] = DateTime.parse(row['week']).strftime('%m-%d-%y') if row['week']
      row['month'] = DateTime.parse(row['month']).strftime('%m-%Y') if row['month']
    end
  end
end
