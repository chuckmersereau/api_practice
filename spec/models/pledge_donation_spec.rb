require 'rails_helper'

RSpec.describe PledgeDonation do
  context '#processed' do
    let(:pledge) { create(:pledge, donations: [donation_one], amount: 400.00) }
    let(:donation_one) { create(:donation, amount: 200.00) }
    let(:donation_two) { create(:donation, amount: 200.00) }

    it 'gets set to false when associated donations are missing from pledge' do
      expect(pledge.processed).to be_falsy

      donation_two.update(pledges: [pledge])

      donation_two.destroy

      expect(pledge.reload.processed).to be_falsy
    end

    it 'gets set to true when donations are all associated to pledge' do
      donation_two.update(pledges: [pledge])

      expect(pledge.processed).to be_truthy
    end
  end
end
