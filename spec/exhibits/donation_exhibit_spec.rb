require 'rails_helper'
describe DonationExhibit do
  subject { DonationExhibit.new(donation, context) }
  let(:donation) { build(:donation, tendered_amount: '1.23', currency: 'USD') }
  let(:context) { double }

  it 'returns a formatted amount' do
    allow(context).to receive(:number_to_current_currency).and_return('$1.23')
    expect(subject.tendered_amount).to eq('$1.23')
  end
end
