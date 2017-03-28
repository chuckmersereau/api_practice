require 'rails_helper'

describe AccountList::PledgeMatcher do
  let(:donor_account)   { build(:donor_account) }
  let(:contact)         { create(:contact, donor_accounts: [donor_account]) }
  let!(:pledge_one)     { create(:pledge, contact: contact, amount: 200.00, expected_date: Date.tomorrow) }
  let!(:pledge_two)     { create(:pledge, contact: contact, amount: 200.00, expected_date: Date.today) }
  let!(:pledge_three)   { create(:pledge, contact: contact, amount: 250.00, expected_date: Date.today) }
  let!(:pledge_four)    { create(:pledge, amount: 250.00, expected_date: Date.today) }

  let(:donation) { build(:donation, donor_account: donor_account, amount: 200.00, donation_date: Date.tomorrow) }

  context '#match' do
    let(:pledge_matcher) { described_class.new(donation: donation, pledge_scope: Pledge) }

    it 'returns an array of pledges that are related to the donation' do
      expect(pledge_matcher.match).to eq([pledge_one])
      donation.donation_date = Date.today
      expect(pledge_matcher.match).to eq([pledge_two])
      donation.amount = 250.00
      expect(pledge_matcher.match).to eq([pledge_three])
    end
  end
end
