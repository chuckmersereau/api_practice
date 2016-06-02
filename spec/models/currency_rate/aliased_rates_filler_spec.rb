require 'spec_helper'

describe CurrencyRate::AliasedRatesFiller, '#fill_aliased_rates' do
  it 'fills in missing rate records for aliases according to their ratio' do
    create(:currency_rate, code: 'KES', rate: 100.0, exchanged_on: Date.new(2016, 5, 1))
    create(:currency_rate, code: 'KES', rate: 110.0, exchanged_on: Date.new(2016, 4, 30))
    create(:currency_alias, alias_code: 'KSH', rate_api_code: 'KES', ratio: 0.5)

    expect do
      CurrencyRate::AliasedRatesFiller.new.fill_aliased_rates
    end.to change(CurrencyRate, :count).by(2)

    expect(CurrencyRate.find_by(code: 'KSH', exchanged_on: Date.new(2016, 5, 1)).rate)
      .to eq 50.0
    expect(CurrencyRate.find_by(code: 'KSH', exchanged_on: Date.new(2016, 4, 30)).rate)
      .to eq 55.0

    # Running a second time does not re-create the same rates
    expect do
      CurrencyRate::AliasedRatesFiller.new.fill_aliased_rates
    end.to_not change(CurrencyRate, :count)
  end
end
