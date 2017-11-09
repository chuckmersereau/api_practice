class AccountList::PledgesTotal
  attr_accessor :account_list, :contacts, :rates

  def initialize(account_list, contacts)
    @account_list = account_list
    @contacts = contacts
    @rates = {}
  end

  def total
    total_usd = contacts.map(&method(:monthly_pledge_usd)).sum
    (total_usd * default_currency_rate).round(2)
  end

  def default_currency_rate
    latest_rate(account_list.salary_currency_or_default)
  end

  def monthly_pledge_usd(partner)
    partner.monthly_pledge / latest_rate(partner.pledge_currency)
  end

  def latest_rate(currency)
    return 1 if currency == 'USD'
    rates[currency] ||= find_latest_rate(currency)
  end

  def find_latest_rate(currency)
    rate = CurrencyRate.where(code: currency).order(exchanged_on: :desc).limit(1).first
    rate ? rate.rate : 1
  end
end
