class Reports::ExpectedMonthlyTotalsSerializer < ServiceSerializer
  delegate :account_list,
           :expected_donations,
           :total_currency,
           :total_currency_symbol,
           to: :object

  belongs_to :account_list

  attributes :expected_donations,
             :total_currency,
             :total_currency_symbol
end
