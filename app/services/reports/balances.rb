class Reports::Balances < ActiveModelSerializers::Model
  include ApplicationHelper

  attr_accessor :account_list

  delegate :designation_accounts, :salary_currency_or_default, to: :account_list

  def total_currency_symbol
    currency_symbol(total_currency)
  end

  def total_currency
    @total_currency ||= salary_currency_or_default
  end
end
