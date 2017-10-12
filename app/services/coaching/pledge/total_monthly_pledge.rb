class Coaching::Pledge::TotalMonthlyPledge
  DEFAULT_CURRENCY = 'USD'.freeze

  attr_accessor :pledges_scope, :currency

  def initialize(pledges_scope, currency)
    @pledges_scope = pledges_scope
    @currency = currency || DEFAULT_CURRENCY
  end

  def total
    pledges_scope.map(&method(:convert_pledge))
                 .inject(0.0, :+)
                 .round(2)
  end

  private

  def convert_pledge(pledge)
    CurrencyRate.convert_with_latest(amount: pledge.amount,
                                     from: pledge.amount_currency,
                                     to: currency)
  rescue CurrencyRate::RateNotFoundError => e
    Rollbar.error(e)
    0
  end
end
