require 'rails_helper'

describe DonationAmountRecommendation::RemoteWorker do
  subject { described_class.new }

  describe '#perform' do
    let(:organization1) { create(:organization) }
    let(:organization2) { create(:organization) }
    let(:donor_account1) { create(:donor_account, organization: organization1) }
    let(:donor_account2) { create(:donor_account, organization: organization2) }
    let(:designation_account1) { create(:designation_account, organization: organization1) }
    let(:designation_account2) { create(:designation_account, organization: organization2) }
    let!(:remote1) do
      create(
        :donation_amount_recommendation_remote,
        donor_number: donor_account1.account_number,
        designation_number: designation_account1.designation_number,
        organization: organization1,
        ask_at: Time.zone.today + 5.days,
        started_at: Time.zone.today - 2.months,
        suggested_pledge_amount: 200
      )
    end
    let!(:remote2) do
      create(
        :donation_amount_recommendation_remote,
        donor_number: donor_account2.account_number,
        designation_number: designation_account2.designation_number,
        organization: organization2,
        ask_at: Time.zone.today + 2.days,
        started_at: Time.zone.today - 1.month,
        suggested_pledge_amount: 30
      )
    end

    it 'should iterate through remote and create donation_amount_recommendations' do
      expect { subject.perform }.to change { DonationAmountRecommendation.count }.from(0).to(2)
      expect(
        DonationAmountRecommendation.where(
          designation_account: designation_account1,
          donor_account: donor_account1,
          ask_at: remote1.ask_at,
          started_at: remote1.started_at,
          suggested_pledge_amount: remote1.suggested_pledge_amount
        )
      ).to_not be_nil
      expect(
        DonationAmountRecommendation.where(
          designation_account: designation_account2,
          donor_account: donor_account2,
          ask_at: remote2.ask_at,
          started_at: remote2.started_at,
          suggested_pledge_amount: remote2.suggested_pledge_amount
        )
      ).to_not be_nil
    end
  end

  context 'unknown organization' do
    before do
      create(:donation_amount_recommendation_remote, organization_id: SecureRandom.uuid)
    end

    it 'should not create donation_amount_recommendation' do
      expect { subject.perform }.to_not change { DonationAmountRecommendation.count }
    end
  end

  context 'unknown donor_number' do
    before do
      create(:donation_amount_recommendation_remote, donor_number: '123')
    end

    it 'should not create donation_amount_recommendation' do
      expect { subject.perform }.to_not change { DonationAmountRecommendation.count }
    end
  end

  context 'unknown designation_number' do
    before do
      create(:donation_amount_recommendation_remote, designation_number: '123')
    end

    it 'should not create donation_amount_recommendation' do
      expect { subject.perform }.to_not change { DonationAmountRecommendation.count }
    end
  end

  context 'donation_amount_recommendation_remote exists' do
    let(:organization) { create(:organization) }
    let(:donor_account) { create(:donor_account, organization: organization) }
    let(:designation_account) { create(:designation_account, organization: organization) }
    let!(:remote) do
      create(
        :donation_amount_recommendation_remote,
        donor_number: donor_account.account_number,
        designation_number: designation_account.designation_number,
        organization: organization,
        ask_at: Time.zone.today + 5.days,
        started_at: Time.zone.today - 2.months,
        suggested_pledge_amount: 200
      )
    end

    it 'should create donation_amount_recommendation' do
      expect { subject.perform }.to change { DonationAmountRecommendation.count }.from(0).to(1)
      donation_amount_recommendation = DonationAmountRecommendation.first
      expect(donation_amount_recommendation.ask_at).to eq(remote.ask_at)
      expect(donation_amount_recommendation.started_at).to eq(remote.started_at)
      expect(donation_amount_recommendation.suggested_pledge_amount).to eq(remote.suggested_pledge_amount)
    end

    context 'donation_amount_recommendation exists' do
      let!(:donation_amount_recommendation) do
        create(
          :donation_amount_recommendation,
          ask_at: Time.zone.today + 1.year,
          started_at: Time.zone.today - 20.days,
          suggested_pledge_amount: 20,
          donor_account: donor_account,
          designation_account: designation_account
        )
      end

      before do
        subject.perform
        donation_amount_recommendation.reload
      end

      it 'should update ask_at' do
        expect(donation_amount_recommendation.ask_at).to eq(remote.ask_at)
      end

      it 'should update started_at' do
        expect(donation_amount_recommendation.started_at).to eq(remote.started_at)
      end

      it 'should update suggested_pledge_amount' do
        expect(donation_amount_recommendation.suggested_pledge_amount).to eq(remote.suggested_pledge_amount)
      end
    end
  end

  context 'donation_amount_recommendation_remote does not exist' do
    let(:organization) { create(:organization) }
    let(:donor_account) { create(:donor_account, organization: organization) }
    let(:designation_account) { create(:designation_account, organization: organization) }

    context 'donation_amount_recommendation exists' do
      let!(:donation_amount_recommendation) do
        create(
          :donation_amount_recommendation,
          ask_at: Time.zone.today + 1.year,
          started_at: Time.zone.today - 20.days,
          suggested_pledge_amount: 20,
          donor_account: donor_account,
          designation_account: designation_account,
          updated_at: 1.day.ago
        )
      end

      it 'should delete donation_amount_recommendation' do
        subject.perform
        expect { donation_amount_recommendation.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
