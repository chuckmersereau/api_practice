class Reports::MonthlyGivingGraphSerializer < ServiceSerializer
  include DisplayCase::ExhibitsHelper

  delegate :account_list,
           :totals,
           :pledges,
           :monthly_average,
           :monthly_goal,
           :months_to_dates,
           to: :object

  belongs_to :account_list

  attributes :totals,
             :pledges,
             :monthly_average,
             :monthly_goal,
             :months_to_dates
end
