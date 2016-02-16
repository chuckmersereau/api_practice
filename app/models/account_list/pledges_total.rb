class AccountList::PledgesTotal
  def initialize(account_list)
    @account_list = account_list
  end

  def total(partners)
    sum = 0
    partners.each do |partner|
      if @account_list.default_currency === partner.pledge_currency
        sum = sum + partner.monthly_pledge
        next
      end

      # convert to USD
      usd_total = 0
      rate = CurrencyRate.where(code: partner.pledge_currency).order(exchanged_on: :desc).limit(1).first
      usd_total = partner.monthly_pledge / rate.rate if rate

      # convert to account currency
      if @account_list.default_currency === 'USD'
        sum = sum + usd_total
      else
        rate = CurrencyRate.where(code: @account_list.default_currency).order(exchanged_on: :desc).limit(1).first
        sum = sum + usd_total / rate.rate if rate
      end
    end

    sum
  end
end
