class DesignationAccountSerializer < ApplicationSerializer
  include ApplicationHelper

  delegate :account_list, :account_lists, :currency, :organization, to: :object
  delegate :name, to: :organization, prefix: true

  attributes :designation_number, :organization_name, :balance, :name,
             :currency, :currency_symbol, :converted_balance, :exchange_rate,
             :balance_updated_at, :active

  def currency_symbol
    super(object.currency)
  end

  def converted_balance
    object.converted_balance(total_currency).to_f
  end

  def total_currency
    list.salary_currency_or_default
  end

  def exchange_rate
    CurrencyRate.latest_for_pair(from: currency, to: total_currency)
  rescue CurrencyRate::RateNotFoundError => e
    Rollbar.error(e)
    'missing'
  end

  def active
    object.active && object.organization_id == list.salary_organization_id
  end

  private

  def list
    scope.is_a?(User) ? account_list(scope) : account_lists.first
  end
end
