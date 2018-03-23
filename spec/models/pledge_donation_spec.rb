require 'rails_helper'

RSpec.describe PledgeDonation do
  context '#processed status' do
    let(:appeal) { create(:appeal) }
    let(:pledge) { create(:pledge, donations: [donation_one], amount: 400.00, appeal: appeal) }
    let(:donation_one) { create(:donation, amount: 200.00, appeal: appeal) }
    let(:donation_two) { create(:donation, amount: 200.00, appeal: appeal) }

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

    it 'can be destroyed if pledge is nil' do
      pledge = PledgeDonation.create

      expect { pledge.destroy }.to_not raise_exception
    end
  end
end
