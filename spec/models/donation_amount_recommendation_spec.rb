require 'rails_helper'

RSpec.describe DonationAmountRecommendation, type: :model do
  subject { create(:donation_amount_recommendation) }

  it { is_expected.to belong_to(:designation_account) }
  it { is_expected.to belong_to(:donor_account) }
  it { is_expected.to validate_presence_of(:designation_account) }
  it { is_expected.to validate_presence_of(:donor_account) }
end
