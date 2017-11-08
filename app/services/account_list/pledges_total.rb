class AccountList::PledgesTotal
  def initialize(account_list, contacts)
    @account_list = account_list
    @contacts = contacts
    @rates = {}
  end

  def total
    if $rollout.active?(:currencies, @account_list)
      total_usd = @contacts.map(&method(:monthly_pledge_usd)).sum
      (total_usd * default_currency_rate).round(2)
    else
      @contacts.to_a.sum(&:monthly_pledge).round(2)
    end
  end

  def default_currency_rate
    latest_rate(@account_list.salary_currency)
  end

  def monthly_pledge_usd(partner)
    partner.monthly_pledge / latest_rate(partner.pledge_currency)
  end

  def latest_rate(currency)
    return 1 if currency == 'USD'
    @rates[currency] ||= find_latest_rate(currency)
  end

  def find_latest_rate(currency)
    rate = CurrencyRate.where(code: currency).order(exchanged_on: :desc).limit(1).first
    rate ? rate.rate : 1
  end
end
