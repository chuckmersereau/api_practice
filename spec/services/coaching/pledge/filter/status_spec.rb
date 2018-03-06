require 'rails_helper'

RSpec.describe Coaching::Pledge::Filter::Status do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }
  let(:contact) { create :contact, account_list: account_list }

  let(:appeal) { create :appeal, account_list: account_list }

  let!(:pledge_completed) do
    create :pledge, appeal: appeal, account_list: account_list, status: :processed
  end

  let!(:pledge_outstanding) do
    create :pledge, appeal: appeal, account_list: account_list,
                    status: :not_received, expected_date: 1.week.ago
  end

  let!(:pledge_pending) do
    create :pledge, appeal: appeal, account_list: account_list,
                    status: :not_received, expected_date: 1.week.from_now
  end

  let!(:pledge_received_not_processed) do
    create :pledge, appeal: appeal, account_list: account_list,
                    status: :received_not_processed,
                    expected_date: 1.week.from_now
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(
        multiple: false,
        name: :status,
        options: [{ name: '-- All --', id: 'all' },
                  { name: 'Outstanding', id: 'outstanding' },
                  { name: 'Completed', id: 'completed' },
                  { name: 'Pending', id: 'pending' },
                  { name: 'Received, but not Processed', id: 'received_not_processed' }],
        title: 'Pledge Status',
        type: 'radio'
      )
    end
  end

  describe '#query' do
    subject { described_class.query(pledges, { status: filter }, nil).to_a }

    let(:pledges) { Pledge.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(pledges, {}, nil)).to eq(nil)
        expect(described_class.query(pledges, { status: {} }, nil)).to eq(nil)
        expect(described_class.query(pledges, { status: [] }, nil)).to eq(nil)
      end
    end

    context 'filter by all pledges' do
      let(:filter) { 'all' }
      it 'accepts "all" as a filter' do
        expect(subject).to include pledge_completed, pledge_outstanding,
                                   pledge_pending, pledge_received_not_processed
      end
    end

    context 'filter by all pledges' do
      let(:filter) { 'unknown filter' }

      it 'treats an unknown value as "all"' do
        expect(subject).to include pledge_completed, pledge_outstanding,
                                   pledge_pending, pledge_received_not_processed
      end
    end

    context 'filter by completed pledges' do
      let(:filter) { 'completed' }
      it 'accepts "completed" as a filter' do
        expect(subject).to include pledge_completed
        expect(subject).not_to include pledge_outstanding, pledge_pending,
                                       pledge_received_not_processed
      end
    end

    context 'filter by outstanding pledges' do
      let(:filter) { 'outstanding' }
      it 'accepts "outstanding" as a filter' do
        expect(subject).to include pledge_outstanding
        expect(subject).not_to include pledge_completed, pledge_pending,
                                       pledge_received_not_processed
      end
    end

    context 'filter by pending pledges' do
      let(:filter) { 'pending' }
      it 'accepts "pending" as a filter' do
        expect(subject).to include pledge_pending
        expect(subject).not_to include pledge_completed, pledge_outstanding,
                                       pledge_received_not_processed
      end
    end

    context 'filter by received, but not processed pledges' do
      let(:filter) { 'received_not_processed' }
      it 'accepts "received_not_processed" as a filter' do
        expect(subject).to include pledge_received_not_processed
        expect(subject).not_to include pledge_outstanding, pledge_completed,
                                       pledge_pending
      end
    end
  end
end
