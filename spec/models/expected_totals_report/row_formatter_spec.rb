require 'spec_helper'

module ExpectedTotalsReport
  describe RowFormatter, '#format' do
    it 'converts currency and expands out contact fields' do
      allow(CurrencyRate).to receive(:latest_for_pair) { 0.5 }
      account_list = build_stubbed(:account_list, salary_currency: 'USD')
      contact = build_stubbed(:contact,
                              name: 'Joe', pledge_currency: 'EUR',
                              pledge_amount: 2, status: 'Partner - Special',
                              pledge_frequency: 1)
      row = { type: 'likely', contact: contact, donation_amount: 10,
              donation_currency: 'EUR' }

      formatted = RowFormatter.new(account_list).format(row)

      expect(formatted[:type]).to eq 'likely'
      expect(formatted[:donor]).to eq 'Joe'
      expect(formatted[:status]).to eq 'Partner - Special'
      expect(formatted[:pledge_amount]).to eq 2
      expect(formatted[:pledge_frequency]).to eq 'Monthly'
      expect(formatted[:pledge_currency]).to eq 'EUR'
      expect(formatted[:pledge_currency_symbol]).to eq '€'
      expect(formatted[:donation_amount]).to eq 10
      expect(formatted[:donation_currency]).to eq 'EUR'
      expect(formatted[:donation_currency_symbol]).to eq '€'
      expect(formatted[:converted_amount]).to eq 5
      expect(formatted[:converted_currency]).to eq 'USD'
      expect(formatted[:converted_currency_symbol]).to eq '$'
      expect(CurrencyRate).to have_received(:latest_for_pair)
        .with(from: 'EUR', to: 'USD')
    end
  end
end
