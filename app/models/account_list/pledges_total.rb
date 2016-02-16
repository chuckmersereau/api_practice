class AccountList::PledgesTotal
  def initialize(account_list)
    @account_list = account_list
  end

  def default_currency_rate
    return 1 if @account_list.default_currency === 'USD'

    rate = CurrencyRate.where(code: @account_list.default_currency).order(exchanged_on: :desc).limit(1).first
    rate ? rate.rate : 1
  end

  def monthly_pledge_usd(partner)
    return partner.monthly_pledge if partner.pledge_currency === 'USD'

    rate = CurrencyRate.where(code: partner.pledge_currency).order(exchanged_on: :desc).limit(1).first
    partner.monthly_pledge / rate.rate if rate
  end

  def total(partners)
    total_usd = partners.map(&method(:monthly_pledge_usd)).reduce(&:+)
    total_usd / default_currency_rate
  end
end
