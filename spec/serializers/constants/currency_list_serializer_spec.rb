require 'spec_helper'

describe Constants::CurrencyListSerializer do
  subject { Constants::CurrencyListSerializer.new(currency_list) }
  let(:currency_list) { Constants::CurrencyList.new }

  context '#currencys' do
    it { expect(subject.currencies).to be_an Array }

    it 'should consist of string/symbol pairs' do
      subject.currencies.each do |currency|
        expect(currency.size).to eq 2
        expect(currency.first).to be_a(String)
        expect(currency.second).to be_a(String)
      end
    end
  end

  context '#currencys_exhibit' do
    it { expect(subject.currencies_exhibit).to be_a CurrencyListExhibit }
  end
end
