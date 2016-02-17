class AccountList::PledgesTotal
  def initialize(account_list)
    @account_list = account_list
  end

  def default_currency_rate
    latest_rate(@account_list.default_currency)
  end

  def monthly_pledge_usd(partner)
    return partner.monthly_pledge if partner.pledge_currency === 'USD'
    partner.monthly_pledge / latest_rate(partner.pledge_currency)
  end

  def total
    total_usd = @account_list.contacts.financial_partners.map(&method(:monthly_pledge_usd)).reduce(&:+)
    total_usd / default_currency_rate
  end

  def latest_rate(currency)
    return 1 if currency === 'USD'

    rate = CurrencyRate.where(code: currency).order(exchanged_on: :desc).limit(1).first
    rate ? rate.rate : 1
  end
end
