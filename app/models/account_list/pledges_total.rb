class AccountList::PledgesTotal
  def initialize(account_list)
    @account_list = account_list
  end

  def default_currency_rate
    return 1 if @account_list.default_currency === 'USD'
    latest_rate(@account_list.default_currency)
  end

  def monthly_pledge_usd(partner)
    return partner.monthly_pledge if partner.pledge_currency === 'USD'
    partner.monthly_pledge / latest_rate(partner.pledge_currency)
  end

  def total(partners)
    total_usd = partners.map(&method(:monthly_pledge_usd)).reduce(&:+)
    total_usd / default_currency_rate
  end

  def latest_rate(currency)
    rate = CurrencyRate.where(code: currency).order(exchanged_on: :desc).limit(1).first
    rate ? rate.rate : 1
  end
end
