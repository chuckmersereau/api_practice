class CurrencyRate < ActiveRecord::Base
  class << self
    def latest_for(currency_code)
      rate_on_date(currency_code: currency_code, date: Date.current)
    end

    def latest_for_pair(from:, to:)
      return 1.0 if from == to
      from_rate = latest_for(from)
      to_rate = latest_for(to)
      to_rate / from_rate
    end

    def convert_with_latest(amount:, from:, to:)
      rate = latest_for_pair(from: from, to: to)
      amount.to_f * rate
    end

    def convert_on_date(amount:, from:, to:, date:)
      rate = rate_for_pair_on_date(from: from, to: to, date: date)
      amount.to_f * rate
    end

    def rate_for_pair_on_date(from:, to:, date:)
      return 1.0 if from == to
      from_rate = rate_on_date(currency_code: from, date: date)
      to_rate = rate_on_date(currency_code: to, date: date)
      to_rate / from_rate
    end

    def rate_on_date(currency_code:, date:)
      return 1.0 if currency_code == 'USD'
      @cached_rates ||= {}
      @cached_rates[currency_code] ||= {}
      @cached_rates[currency_code][date] ||= find_rate_on_date(
        currency_code: currency_code, date: date)
    end

    def cache_rates_for_dates(currency_code:, from_date:, to_date:)
      return if currency_code == 'USD'
      return if cached_rates_for_date_range?(currency_code, from_date, to_date)

      (from_date..to_date).each do |date|
        rate_on_date(currency_code: currency_code, date: date)
      end
    end

    def clear_rate_cache
      @cached_rates = {}
    end

    private

    def find_rate_on_date(currency_code:, date:)
      return 1.0 if currency_code.blank?
      rate_record =
        where(code: currency_code).where('exchanged_on >= ?', date)
                                  .order(:exchanged_on).first ||
        where(code: currency_code).where('exchanged_on < ?', date)
                                  .order(exchanged_on: :desc).first
      raise RateNotFoundError, currency_code unless rate_record
      rate_record.rate
    rescue RateNotFoundError => e
      # If a rate cannot be found, log that error to rollbar so we can debug it
      # easily, but gracefully fall back to a rate of 1.0
      Rollbar.error(e)
      1.0
    end

    def cached_rates_for_date_range?(currency_code, from_date, to_date)
      return false unless @cached_rates
      cached_rates_by_date = @cached_rates[currency_code]
      return false unless cached_rates_by_date.present?
      (from_date..to_date).all? do |date|
        cached_rates_by_date[date].present?
      end
    end
  end

  class RateNotFoundError < StandardError
  end
end
