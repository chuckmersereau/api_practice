require 'rails_helper'

RSpec.describe Coaching::Contact::Filter::Pledge do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(
        multiple: false,
        name: :pledge,
        options: [{ name: '-- All --', id: 'all' },
                  { name: 'Outstanding', id: 'outstanding' },
                  { name: 'Completed', id: 'completed' },
                  { name: 'Pending', id: 'pending' }],
        title: 'Pledge Status',
        type: 'radio'
      )
    end
  end

  describe '#query' do
    let!(:contact_completed) do
      create :contact, account_list_id: account_list.id, pledge_received: true
    end

    let!(:contact_outstanding) do
      create :contact, account_list_id: account_list.id, pledge_received: false,
                       pledge_start_date: 2.days.ago
    end

    let!(:contact_pending) do
      create :contact, account_list_id: account_list.id, pledge_received: false,
                       pledge_start_date: 2.days.from_now
    end

    let!(:contact_completed_start_past) do
      create :contact, account_list_id: account_list.id, pledge_received: true,
                       pledge_start_date: 2.days.ago
    end

    let!(:contact_completed_start_future) do
      create :contact, account_list_id: account_list.id, pledge_received: true,
                       pledge_start_date: 2.days.from_now
    end

    let!(:used_to_be_committed) do
      create :contact, account_list_id: account_list.id, pledge_received: false,
                       status: 'Partner - Pray', pledge_start_date: 2.days.ago
    end
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge: [] }, nil)).to eq(nil)
      end
    end

    context 'filter by all contacts' do
      it 'accepts "all" as a filter' do
        expect(described_class.query(contacts, { pledge: 'all' }, nil).to_a) \
          .to match_array [contact_completed, contact_outstanding, contact_pending,
                           contact_completed_start_past, contact_completed_start_future,
                           used_to_be_committed]
      end

      it 'treats an unknown value as "all"' do
        expect(described_class.query(contacts, { pledge: 'unknown filter' }, nil).to_a) \
          .to match_array [contact_completed, contact_outstanding, contact_pending,
                           contact_completed_start_past, contact_completed_start_future,
                           used_to_be_committed]
      end
    end

    context 'filter by completed contacts' do
      it 'accepts "completed" as a filter' do
        expect(described_class.query(contacts, { pledge: 'completed' }, nil).to_a) \
          .to include contact_completed, contact_completed_start_past,
                      contact_completed_start_future
        expect(described_class.query(contacts, { pledge: 'completed' }, nil).to_a) \
          .not_to include contact_outstanding, contact_pending, used_to_be_committed
      end
    end

    context 'filter by outstanding contacts' do
      it 'accepts "outstanding" as a filter' do
        expect(described_class.query(contacts, { pledge: 'outstanding' }, nil).to_a) \
          .to include contact_outstanding
        expect(described_class.query(contacts, { pledge: 'outstanding' }, nil).to_a) \
          .not_to include contact_completed, contact_pending,
                          contact_completed_start_past,
                          contact_completed_start_future,
                          used_to_be_committed
      end
    end

    context 'filter by pending contacts' do
      it 'accepts "pending" as a filter' do
        expect(described_class.query(contacts, { pledge: 'pending' }, nil).to_a) \
          .to include contact_pending
        expect(described_class.query(contacts, { pledge: 'pending' }, nil).to_a) \
          .not_to include contact_completed, contact_outstanding,
                          contact_completed_start_past,
                          contact_completed_start_future,
                          used_to_be_committed
      end
    end
  end
end
