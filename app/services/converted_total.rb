# takes in an array of arrays [amount, currency]
class ConvertedTotal
  attr_accessor :array, :rates, :display_currency

  def initialize(array, display_currency)
    @array = array
    @rates = {}
    @display_currency = display_currency
  end

  def total
    array.map do |obj|
      convert_on_date(obj[0], obj[1], obj[2])
    end.sum.round(2)
  end

  def convert_on_date(amount, currency, date)
    CurrencyRate.convert_on_date(
      amount: amount,
      from: currency,
      to: display_currency,
      date: date
    )
  end
end
