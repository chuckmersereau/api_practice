require 'spec_helper'

describe CurrencyRate do
  before { CurrencyRate.clear_rate_cache }

  context '.latest_for' do
    it 'returns the latest exchange rate for currency' do
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 1, 1), rate: 0.8)
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 2, 1), rate: 0.7)

      expect(CurrencyRate.latest_for('EUR')).to eq 0.7
    end

    it 'logs a missing rate exception to Rollbar and returns 1.0 if rate missing' do
      expect(Rollbar).to receive(:error) do |error|
        expect(error).to be_a(CurrencyRate::RateNotFoundError)
      end

      expect(CurrencyRate.latest_for('EUR')).to eq 1.0
    end

    it 'returns 1.0 and does not log a Rollbar exception for nil currency' do
      expect(Rollbar).to_not receive(:error)
      expect(CurrencyRate.latest_for(nil)).to eq 1.0
    end
  end

  context '.latest_for_pair' do
    it 'retrieves composite rate between currencies' do
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 0.88)
      create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 0.69)

      expect(CurrencyRate.latest_for_pair(from: 'EUR', to: 'GBP'))
        .to be_within(0.01).of(0.78)
    end

    it 'returns 1.0 if the currencies are the same' do
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 0.88)

      expect(CurrencyRate.latest_for_pair(from: 'EUR', to: 'EUR')).to eq 1.0
    end
  end

  context '.convert_with_latest' do
    it 'converts from one currency to other using latest rates' do
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 0.88)
      create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 0.69)

      expect(CurrencyRate.convert_with_latest(amount: 10.0, from: 'EUR', to: 'GBP'))
        .to be_within(0.1).of(7.8)
    end
  end

  context '.convert_on_date' do
    it 'converts from one currency to other using latest rates' do
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 0.88)
      create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 0.69)
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 2), rate: 0.5)
      create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 2), rate: 0.5)

      expect(CurrencyRate.convert_on_date(
               amount: 10, from: 'EUR', to: 'GBP', date: Date.new(2016, 4, 1)))
        .to be_within(0.1).of(7.8)
    end

    it 'uses the oldest currency rate after that date for rates with no dates' do
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 0.88)
      create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 0.69)

      expect(CurrencyRate.convert_on_date(
               amount: 10, from: 'EUR', to: 'GBP', date: Date.new(2016, 3, 1)))
        .to be_within(0.1).of(7.8)
    end

    it 'still works if you cache the currency rate date range first' do
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 0.88)
      create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 0.69)
      CurrencyRate.cache_rates_for_dates(
        currency_code: 'EUR', from_date: Date.new(2016, 3, 30),
        to_date: Date.new(2016, 4, 2))

      expect(CurrencyRate.convert_on_date(
               amount: 10, from: 'EUR', to: 'GBP', date: Date.new(2016, 4, 1)))
        .to be_within(0.1).of(7.8)
    end
  end
end
