require 'rails_helper'

describe AccountList::PledgeMatcher do
  subject { described_class.new(donation) }

  let!(:donation) do
    build(:donation, donor_account: donor_account, appeal: appeal,
                     amount: 200.00, appeal_amount: 100.00)
  end

  let(:donor_account) { build(:donor_account) }
  let(:appeal)        { create(:appeal, account_list: account_list) }
  let(:account_list)  { create(:account_list) }
  let!(:contact) do
    create(:contact, donor_accounts: [donor_account],
                     account_list: account_list, appeals: [appeal])
  end

  context 'a Pledge already exists' do
    let!(:pledge) do
      create(:pledge, appeal: appeal, contact: contact, amount: 250.00)
    end

    describe '#needs_pledge?' do
      it 'cannot assign a Pledge if there already is one' do
        donation.update! pledges: [pledge]
        expect(subject.needs_pledge?).to be false
      end

      it 'returns true if there is an Appeal and no existing PledgeDonation' do
        expect(subject.needs_pledge?).to be true
      end
    end

    describe '#pledge' do
      it 'returns the pre-existing Pledge' do
        expect(subject.pledge).to eq pledge
      end
    end

    context 'the donation has no associated Appeal' do
      before { donation.appeal = nil }

      it 'will not return a Pledge' do
        expect(subject.pledge).to be_nil
      end

      it 'automatically associates with the existing Pledge when an Appeal is added' do
        donation.save!
        expect(subject.pledge).to be_nil
        expect(donation.pledges).to be_empty

        donation.update!(appeal: appeal)
        expect(donation.pledges).to include pledge
      end
    end
  end

  context 'a Pledge does not already exist' do
    describe '#needs_pledge?' do
      it 'cannot assign a Pledge if there is no associated Appeal' do
        donation.update! appeal: nil
        expect(subject.needs_pledge?).to be false
      end

      it 'returns true if there is an Appeal and no existing Pledge' do
        expect(subject.needs_pledge?).to be true
      end
    end

    describe '#pledge' do
      it 'returns a new Pledge' do
        expect(subject.pledge).to be_a Pledge
      end

      it 'returns a Pledge with the Donation attributes' do
        expect(subject.pledge.amount).to eq donation.pledge_amount
        expect(subject.pledge.expected_date).to eq donation.donation_date
        expect(subject.pledge.account_list).to eq account_list
        expect(subject.pledge.contact).to eq contact
        expect(subject.pledge.amount_currency).to eq donation.currency
        expect(subject.pledge.appeal).to eq donation.appeal
      end

      it 'fills the Pledge with the #appeal_amount' do
        expect(subject.pledge.amount).to eq 100.00
      end

      it 'uses the #amount if there is no #appeal_amount' do
        donation.appeal_amount = nil
        expect(subject.pledge.amount).to eq 200.00
      end

      context 'the donation has no associated Appeal' do
        before { donation.appeal = nil }

        it 'will not return a Pledge' do
          expect(subject.pledge).to be_nil
        end

        it 'automatically creates a new Pledge when an Appeal is added' do
          donation.save!
          expect(subject.pledge).to be_nil
          expect(donation.pledges).to be_empty

          donation.update!(appeal: appeal)
          expect(donation.pledges).not_to be_empty
        end
      end
    end
  end
end
