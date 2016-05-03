class Api::V1::Reports::BalancesController < Api::V1::BaseController
  include LocalizationHelper

  def show
    render json: report_data
  end

  private

  def report_data
    {
      designations: designations,
      total_currency: total_currency,
      total_currency_symbol: currency_symbol(total_currency)
    }
  end

  def designations
    current_account_list.designation_accounts.map do |da|
      {
        organization_name: da.organization.name,
        designation_number: da.designation_number,
        balance: da.balance,
        currency: da.currency,
        currency_symbol: currency_symbol(da.currency),
        converted_balance: da.converted_balance(total_currency).to_f,
        exchange_rate: exchange_rate(da.currency),
        balance_updated_at: da.balance_updated_at,
        active: da.active
      }
    end
  end

  def total_currency
    @total_currency ||= current_account_list.salary_currency_or_default
  end

  def exchange_rate(from_currency)
    CurrencyRate.latest_for_pair(from: from_currency, to: total_currency)
  rescue CurrencyRate::RateNotFoundError => e
    Rollbar.error(e)
    'missing'
  end
end
