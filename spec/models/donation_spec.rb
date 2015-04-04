require 'spec_helper'

describe Donation do
  let(:da) { create(:designation_account) }
  let(:donor_account) { create(:donor_account) }
  let(:donation) { create(:donation) }

  context '#localized_date' do
    it 'is just date' do
      expect(donation.localized_date).to_not be_blank
    end
  end
end
