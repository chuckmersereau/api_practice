require 'rails_helper'

describe AccountList::PledgeMatcher do
  subject { described_class.new(donation) }

  let(:donation) do
    build(:donation, donor_account: donor_account, appeal: appeal, amount: 200.00)
  end

  let(:donor_account) { build(:donor_account) }
  let(:appeal)        { create(:appeal, account_list: account_list) }
  let(:account_list)  { create(:account_list) }
  let!(:contact) do
    create(:contact, donor_accounts: [donor_account],
                     account_list: account_list, appeals: [appeal])
  end

  context 'a pledge already exists' do
    let!(:pledge) do
      create(:pledge, appeal: appeal, contact: contact, amount: 200.00)
    end

    describe '#needs_pledge?' do
      it 'cannot assign a Pledge if there already is one' do
        donation.update! pledges: [pledge]
        expect(subject.needs_pledge?).to be false
      end

      it 'should be true if there is an Appeal and no existing PledgeDonation' do
        expect(subject.needs_pledge?).to be true
      end
    end

    describe '#pledge' do
      it 'should return the pre-existing pledge' do
        expect(subject.pledge).to eq pledge
      end
    end
  end

  context 'a pledge does not already exist' do
    describe '#needs_pledge?' do
      it 'cannot assign a Pledge if there is no associated Appeal' do
        donation.update! appeal: nil
        expect(subject.needs_pledge?).to be false
      end

      it 'should be true if there is an Appeal and no existing Pledge' do
        expect(subject.needs_pledge?).to be true
      end
    end

    describe '#pledge' do
      it 'should return a new Pledge' do
        expect(subject.pledge).to be_a Pledge
      end

      it 'should return a Pledge with the Donation attributes' do
        expect(subject.pledge.amount).to eq donation.amount
        expect(subject.pledge.expected_date).to eq donation.donation_date
        expect(subject.pledge.account_list).to eq account_list
        expect(subject.pledge.contact).to eq contact
        expect(subject.pledge.amount_currency).to eq donation.currency
        expect(subject.pledge.appeal).to eq donation.appeal
      end
    end
  end
end
