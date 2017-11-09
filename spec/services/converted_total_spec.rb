require 'rails_helper'

RSpec.describe ConvertedTotal, type: :service do
  let(:data) do
    [
      [5.50, 'EUR', Date.new(2016, 2, 15)],
      [200.82, 'RUB', Date.new(2017, 1, 21)],
      [10.60, 'NZD', Date.new(2016, 4, 10)]
    ]
  end

  before do
    create(:currency_rate, rate: 0.8, exchanged_on: '2016-02-15', code: 'EUR')
    create(:currency_rate, rate: 0.78, exchanged_on: '2016-02-15', code: 'NZD')
    create(:currency_rate, rate: 75.20, exchanged_on: '2017-01-21', code: 'RUB')
    create(:currency_rate, rate: 0.62, exchanged_on: '2017-01-21', code: 'NZD')
    create(:currency_rate, rate: 0.75, exchanged_on: '2016-04-10', code: 'NZD')
  end

  describe '#total' do
    it 'converts currencies on their display date to the display currency' do
      expect(described_class.new(data, 'NZD').total).to eq(
        (5.50 / 0.8 * 0.78 + 200.82 / 75.20 * 0.62 + 10.60).round(2)
        # EUR > USD > NZD + RUB > USD > NZD + NZD
      )
    end
  end
end
