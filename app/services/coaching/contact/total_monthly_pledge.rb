class Coaching::Contact::TotalMonthlyPledge
  DEFAULT_CURRENCY = 'USD'.freeze

  attr_accessor :contacts_scope, :currency

  def initialize(contacts_scope, currency)
    @contacts_scope = contacts_scope
    @currency = currency || DEFAULT_CURRENCY
  end

  def total
    contacts_scope.map(&method(:convert_pledge))
                  .inject(0.0, :+)
                  .round(2)
  end

  private

  def convert_pledge(contact)
    CurrencyRate.convert_with_latest(amount: contact.monthly_pledge,
                                     from: contact.pledge_currency,
                                     to: currency)
  end
end
