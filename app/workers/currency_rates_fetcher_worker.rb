class CurrencyRatesFetcherWorker
  include Sidekiq::Worker
  sidekiq_options unique: true

  MAX_DAYS_TO_FETCH = 30

  def perform
    num_days_to_fetch.times do |n|
      fetch_rates(Date.current - n)
    end
  end

  private

  def num_days_to_fetch
    last_date = last_rate_exchanged_date
    if last_date.nil?
      MAX_DAYS_TO_FETCH
    else
      [(Date.current - last_date).to_i, MAX_DAYS_TO_FETCH].min
    end
  end

  def last_rate_exchanged_date
    CurrencyRate.order(:exchanged_on).last.try(:exchanged_on)
  end

  def fetch_rates(date)
    json = rates(date)
    fail 'Currency Layer api call failed' unless json['success']
    import_quotes(json['quotes'], date)
  end

  def import_quotes(quotes, date)
    quotes.each do |currencies, rate|
      CurrencyRate.create(exchanged_on: date,
                          code: currencies[3..5], rate: rate,
                          source: 'currencylayer')
    end
  end

  def rates(time)
    return live_currency_rates if time.today?
    historical_rates(time)
  end

  def historical_rates(date)
    currency_layer_call('historical', date: date.strftime('%Y-%m-%d'))
  end

  def live_currency_rates
    currency_layer_call('live')
  end

  def currency_layer_call(action, params = {})
    url = 'http://apilayer.net/api/' + action
    params = params.merge(access_key: ENV.fetch('CURRENCY_LAYER_KEY'))
    JSON.parse(RestClient.get(url, params: params))
  end
end
