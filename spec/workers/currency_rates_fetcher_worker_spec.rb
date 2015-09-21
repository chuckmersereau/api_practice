require 'spec_helper'

describe CurrencyRatesFetcherWorker do
  before { ENV['CURRENCY_LAYER_KEY'] = 'asdf' }

  around do |example|
    travel_to Date.new(2015, 9, 15) do
      example.run
    end
  end

  it 'imports todays rates if they are missing' do
    create(:currency_rate, exchanged_on: Date.new(2015, 9, 14))
    stub_live_rates_success

    expect do
      subject.perform
    end.to change(CurrencyRate, :count).by(2)

    eur = CurrencyRate.find_by(code: 'CHF')
    expect(eur.exchanged_on).to eq Date.new(2015, 9, 15)
    expect(eur.source).to eq 'currencylayer'
    expect(eur.rate.to_f).to eq(0.97535)

    jpy = CurrencyRate.find_by(code: 'JPY')
    expect(jpy.rate.to_f).to eq(120.445007)
  end

  it 'imports multiple previous days rates if missing' do
    create(:currency_rate, exchanged_on: Date.new(2015, 9, 13))
    stub_live_rates_success
    stub_historical_rates(Date.new(2015, 9, 14))
    expect { subject.perform }.to change(CurrencyRate, :count).by(4)

    chf1 = CurrencyRate.find_by(exchanged_on: Date.new(2015, 9, 15), code: 'CHF')
    chf2 = CurrencyRate.find_by(exchanged_on: Date.new(2015, 9, 14), code: 'CHF')
    expect(chf1.rate.to_f).to eq(0.97535)
    expect(chf2.rate.to_f).to eq(0.96782)
  end

  it 'fails if currency layer api call fails' do
    create(:currency_rate, exchanged_on: Date.current - 1)
    stub_live_rates(body: { success: false }.to_json)
    expect { subject.perform }.to raise_error(/failed/)
  end

  it 'loads a maximium of the 30 previous days' do
    stub_live_rates_success
    create(:currency_rate, exchanged_on: Date.current - 31)
    31.times { |i| stub_historical_rates(Date.current - i) }
    expect { subject.perform }.to change(CurrencyRate, :count).by(60)
  end

  it 'imports the past 30 days if there are no rates stored' do
    stub_live_rates_success
    30.times { |i| stub_historical_rates(Date.current - i) }
    expect { subject.perform }.to change(CurrencyRate, :count).by(60)
  end

  def stub_live_rates_success
    stub_live_rates(body: {
      success: true, source: 'USD', quotes: {
        'USDCHF' => 0.97535, 'USDJPY' => 120.445007
      }
    }.to_json)
  end

  def stub_live_rates(stub_to_return)
    stub_request(:get, 'http://apilayer.net/api/live?access_key=asdf')
      .to_return(stub_to_return)
  end

  def stub_historical_rates(date)
    historical_rates = {
      success: true, source: 'USD', quotes: {
        'USDCHF' => 0.96782, 'USDJPY' => 119.962502
      }
    }
    url = "http://apilayer.net/api/historical?access_key=asdf&date=#{date.strftime('%Y-%m-%d')}"
    stub_request(:get, url).to_return(body: historical_rates.to_json)
  end
end
