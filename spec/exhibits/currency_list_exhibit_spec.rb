require 'spec_helper'

describe CurrencyListExhibit do
  let(:context) { double }
  let(:exhibit) { CurrencyListExhibit.new(currency_list, context) }
  let(:currency_list) { Constants::CurrencyList.new }

  context '.applicable_to?' do
    it 'applies only to CurrencyList and not other stuff' do
      expect(CurrencyListExhibit.applicable_to?(Constants::CurrencyList.new)).to be true
      expect(CurrencyListExhibit.applicable_to?(Address.new)).to be false
    end
  end
end
