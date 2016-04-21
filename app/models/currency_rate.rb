class CurrencyRate < ActiveRecord::Base
  def self.latest_for(currency_code)
    return 1.0 if currency_code == 'USD'
    rate_record = where(code: currency_code).order(exchanged_on: :desc).first
    raise RateNotFoundError, currency_code unless rate_record
    rate_record.rate
  end

  def self.latest_for_pair(from:, to:)
    return 1.0 if from == to
    from_rate = latest_for(from)
    to_rate = latest_for(to)
    from_rate * to_rate
  end

  def self.convert_with_latest(amount:, from:, to:)
    rate = latest_for_pair(from: from, to: to)
    amount.to_f * rate
  end

  class RateNotFoundError < StandardError
  end
end
