require 'rails_helper'

RSpec.describe DonationAmountRecommendation, type: :model do
  subject { build(:donation_amount_recommendation) }

  it { is_expected.to belong_to(:designation_account) }
  it { is_expected.to belong_to(:donor_account) }
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to validate_presence_of(:designation_account) }
  it { is_expected.to validate_presence_of(:donor_account) }
  it { is_expected.to validate_presence_of(:organization) }
  it { is_expected.to validate_uniqueness_of(:organization_id).scoped_to([:donor_number, :designation_number]) }

  it 'should validate donor_account belongs to same organization' do
    subject.donor_account = create(:donor_account)
    expect(subject).to_not be_valid
    expect(subject.errors[:donor_account]).to be_present
  end

  it 'should validate designation_account belongs to same organization' do
    subject.designation_account = create(:designation_account)
    expect(subject).to_not be_valid
    expect(subject.errors[:designation_account]).to be_present
  end

  describe 'donor_account association' do
    let(:organization) { create :organization }
    subject { create :donation_amount_recommendation, organization: organization }

    it 'should allow donor_account to be joined from association' do
      expect { organization.donation_amount_recommendations.joins(:donor_account) }.to_not raise_error
    end

    it 'should allow donor_account to be retrived from instance' do
      expect(subject.donor_account.organization).to eq organization
    end

    it 'should not map donor_account that belongs to a different organization' do
      donor_account = create :donor_account, account_number: '1234'
      subject.update(donor_number: '1234')
      expect(subject.organization).to_not eq donor_account.organization
      expect(subject.donor_account).to be_nil
    end
  end

  describe 'designation_account association' do
    let(:organization) { create :organization }
    subject { create :donation_amount_recommendation, organization: organization }

    it 'should allow designation_account to be joined from association' do
      expect { organization.donation_amount_recommendations.joins(:designation_account) }.to_not raise_error
    end

    it 'should allow designation_account to be retrived from instance' do
      expect(subject.designation_account.organization).to eq organization
    end

    it 'should not map designation_account that belongs to a different organization' do
      designation_account = create :designation_account, designation_number: '1234'
      subject.update(designation_number: '1234')
      expect(subject.organization).to_not eq designation_account.organization
      expect(subject.designation_account).to be_nil
    end
  end
end
