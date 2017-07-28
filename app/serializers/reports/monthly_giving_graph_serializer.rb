class Reports::MonthlyGivingGraphSerializer < ServiceSerializer
  include DisplayCase::ExhibitsHelper

  delegate :account_list,
           :totals,
           :pledges,
           :monthly_average,
           :monthly_goal,
           :months_to_dates,
           :multi_currency,
           :salary_currency,
           :display_currency,
           to: :object

  delegate :salary_currency_symbol,
           to: :report_exhibit

  belongs_to :account_list

  attributes :totals,
             :pledges,
             :monthly_average,
             :monthly_goal,
             :months_to_dates,
             :multi_currency,
             :salary_currency_symbol,
             :salary_currency,
             :display_currency

  def report_exhibit
    exhibit(object)
  end
end
