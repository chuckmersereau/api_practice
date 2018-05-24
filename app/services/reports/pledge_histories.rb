class Reports::PledgeHistories < Reports::Base
  protected

  def default_range
    '13m'
  end

  def generate_report_for_period(start_date:, end_date:)
    Reports::PledgeHistoriesPeriod.new(account_list: account_list,
                                       start_date: start_date,
                                       end_date: end_date)
  end
end
