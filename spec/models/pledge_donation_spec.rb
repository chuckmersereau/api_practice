require 'rails_helper'

RSpec.describe PledgeDonation do
  context '#processed status' do
    let(:pledge) { create(:pledge, donations: [donation_one], amount: 400.00) }
    let(:donation_one) { create(:donation, amount: 200.00) }
    let(:donation_two) { create(:donation, amount: 200.00) }

    it 'is removed when associated donations are missing from pledge' do
      expect(pledge).to_not be_processed

      donation_two.update(pledges: [pledge])

      donation_two.destroy

      expect(pledge.reload).to_not be_processed
    end

    it 'is added when donations are all associated to pledge' do
      donation_two.update(pledges: [pledge])

      expect(pledge).to be_processed
    end
  end
end
