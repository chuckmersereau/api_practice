require 'spec_helper'

module ExpectedTotalsReport
  describe Api::V1::Reports::ExpectedMonthlyTotalsController do
    context '#show' do
      it 'works' do
        account_list = create(:account_list)
        user = create(:user)
        user.account_lists << account_list
        login(user)
        formatter = instance_double(RowFormatter, total_currency: 'USD',
                                                  total_currency_symbol: '$')
        allow(RowFormatter).to receive(:new) { formatter }
        allow(formatter).to receive(:format)
          .and_return('formatted_row1', 'formatted_row2')
        received_row = { type: 'received', contact: double,
                         donation_amount: 1, donation_currency: 'EUR' }
        received = instance_double(ReceivedDonations, donation_rows: [received_row])
        allow(ReceivedDonations).to receive(:new) { received }
        possible_row = { type: 'likely', contact: double,
                         donation_amount: 1, donation_currency: 'EUR' }
        possible = instance_double(PossibleDonations, donation_rows: [possible_row])
        allow(PossibleDonations).to receive(:new) { possible }

        get :show

        expect(JSON.parse(response.body)).to eq(
          'donations' => %w(formatted_row1 formatted_row2),
          'total_currency' => 'USD', 'total_currency_symbol' => '$'
        )
      end
    end
  end
end
