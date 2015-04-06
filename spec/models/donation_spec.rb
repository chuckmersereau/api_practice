require 'spec_helper'

describe Donation do
  let(:donation) { create(:donation, donation_date: Date.new(2015, 4, 5)) }

  context '#localized_date' do
    it 'is just date' do
      expect(donation.localized_date).to eq 'April 05, 2015'
    end
  end
end
