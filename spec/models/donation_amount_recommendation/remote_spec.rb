require 'rails_helper'

RSpec.describe DonationAmountRecommendation::Remote, type: :model do
  let(:organization) { create(:organization) }
  let(:designation_account) { create(:designation_account, organization: organization) }
  let(:donor_account) { create(:donor_account, organization: organization) }

  subject do
    create(
      :donation_amount_recommendation_remote,
      organization: organization,
      designation_number: designation_account.designation_number,
      donor_number: donor_account.account_number
    )
  end

  it { is_expected.to belong_to(:organization) }

  describe '#designation_account' do
    it 'should retrieve designation_account' do
      expect(subject.designation_account).to eq designation_account
    end

    context 'designation_number is nil' do
      before { subject.designation_number = nil }

      it 'should return nil' do
        expect(subject.designation_account).to be_nil
      end
    end

    context 'designation_number is non existent' do
      before { subject.designation_number = '123' }

      it 'should return nil' do
        expect(subject.designation_account).to be_nil
      end
    end

    context 'organization is nil' do
      before { subject.organization = nil }

      it 'should return nil' do
        expect(subject.designation_account).to be_nil
      end
    end
  end

  describe '#donor_account' do
    it 'should retrieve donor_account' do
      expect(subject.donor_account).to eq donor_account
    end

    context 'donor_number is nil' do
      before { subject.donor_number = nil }

      it 'should return nil' do
        expect(subject.donor_account).to be_nil
      end
    end

    context 'donor_number is non existent' do
      before { subject.donor_number = '123' }

      it 'should return nil' do
        expect(subject.donor_account).to be_nil
      end
    end

    context 'organization is nil' do
      before { subject.organization = nil }

      it 'should return nil' do
        expect(subject.designation_account).to be_nil
      end
    end
  end
end
