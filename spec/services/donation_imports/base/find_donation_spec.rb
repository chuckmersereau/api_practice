require 'rails_helper'

RSpec.describe DonationImports::Base::FindDonation do
  let(:designation_profile) { create(:designation_profile) }
  let(:attributes) { {} }

  describe 'initialize' do
    it 'initializes' do
      new_instance = described_class.new(designation_profile: designation_profile, attributes: attributes)
      expect(new_instance).to be_a(described_class)
    end
  end

  describe '#find_and_merge' do
    let(:des_account1) { create(:designation_account) }
    let(:des_account2) { create(:designation_account) }
    let(:donor_account) { create(:donor_account) }
    let(:finder) { described_class.new(designation_profile: designation_profile, attributes: attributes) }

    before do
      designation_profile.designation_accounts << des_account1
      designation_profile.designation_accounts << des_account2
    end

    it 'finds donations by their remote id or tnt id in multiple designation accounts' do
      d1 = create(:donation, remote_id: '1234', tnt_id: nil, designation_account: des_account1)
      d2 = create(:donation, remote_id: nil, tnt_id: '1234', designation_account: des_account2)
      d3 = create(:donation, remote_id: 'abcd', tnt_id: 'abcd', designation_account: des_account2)

      attributes[:remote_id] = '1234'

      found_donation = nil
      expect { found_donation = finder.find_and_merge }.to change { Donation.count }.from(3).to(2)
      expect([d1, d2, d3]).to include(found_donation)
      expect(found_donation.reload.tnt_id).to eq('1234')
      expect(found_donation.remote_id).to eq('1234')
    end

    it 'finds donations by their donor, amount, and date in multiple designation accounts' do
      base_attributes = { remote_id: nil, tnt_id: '1234', amount: 1.0,
                          donation_date: Date.new, donor_account: donor_account }
      d1 = create(:donation, base_attributes.merge(designation_account: des_account1))
      d2 = create(:donation, base_attributes.merge(designation_account: des_account2))

      attributes[:remote_id] = 'abcd'
      attributes[:donor_account_id] = donor_account.id
      attributes[:amount] = 1.0
      attributes[:donation_date] = Date.new

      expect do
        expect([d1, d2]).to include(finder.find_and_merge)
      end.to change { Donation.count }.from(2).to(1)
    end

    it 'also looks on placeholder account' do
      account_list = create(:account_list)
      designation_profile.update(account_list: account_list)

      placeholder_account = account_list.designation_accounts.create!(organization: Organization.first,
                                                                      name: 'User (Imported from TntConnect)')

      d1 = create(:donation, remote_id: '1234', tnt_id: nil, designation_account: des_account1)
      d2 = create(:donation, remote_id: nil, tnt_id: '1234', designation_account: placeholder_account)

      attributes[:remote_id] = '1234'

      expect do
        expect([d1, d2]).to include(finder.find_and_merge)
      end.to change { Donation.count }.from(2).to(1)
    end
  end
end
