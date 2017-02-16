class ExpectedTotalsReport::RowFormatter
  include LocalizationHelper

  def initialize(account_list)
    @account_list = account_list
    @currency_rates = {}
  end

  def format(type:, contact:, donation_amount:, donation_currency:)
    {
      contact_id: contact.uuid,
      contact_name: contact.name,
      contact_status: _(contact.status),
      converted_amount: (donation_amount * rate_for_currency(donation_currency)).to_f,
      converted_currency: total_currency,
      converted_currency_symbol: total_currency_symbol,
      donation_amount: donation_amount.to_f,
      donation_currency: donation_currency,
      donation_currency_symbol: currency_symbol(donation_currency),
      pledge_amount: contact.pledge_amount.to_f,
      pledge_currency: contact.pledge_currency,
      pledge_currency_symbol: currency_symbol(contact.pledge_currency),
      pledge_frequency: _(Contact.pledge_frequencies[contact.pledge_frequency]),
      type: type
    }
  end

  def total_currency_symbol
    currency_symbol(total_currency)
  end

  def total_currency
    @account_list.salary_currency_or_default
  end

  private

  def rate_for_currency(currency)
    @currency_rates[currency] ||=
      CurrencyRate.latest_for_pair(from: currency, to: total_currency)
  end
end
