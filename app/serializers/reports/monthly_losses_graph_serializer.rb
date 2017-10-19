class Reports::MonthlyLossesGraphSerializer < ServiceSerializer
  include DisplayCase::ExhibitsHelper

  delegate :account_list,
           :month_names,
           :losses,
           to: :object

  belongs_to :account_list

  attributes :account_list,
             :month_names,
             :losses
end
