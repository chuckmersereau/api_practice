class Reports::BalancesSerializer < ServiceSerializer
  delegate :account_list,
           :total_currency,
           :total_currency_symbol,
           :designation_accounts,
           to: :object

  belongs_to :account_list
  has_many :designation_accounts

  attributes :total_currency, :total_currency_symbol
end
