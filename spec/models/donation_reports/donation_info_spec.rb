require 'spec_helper'

describe DonationReports::DonationInfo do
  let(:account_list) { create(:account_list) }
  let(:donation) { create(:donation) }

  describe '.from_donation' do
    it 'intantiates an object with attributes' do
      donation_info = DonationReports::DonationInfo.from_donation(donation)
      expect(donation_info.amount).to eq(donation.amount)
    end
  end
end
