require 'rails_helper'

RSpec.describe Contact::Filter::Status do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  describe '#query' do
    let!(:active_contact) { create(:contact, account_list: account_list, status: 'Ask in Future') }
    let!(:inactive_contact) { create(:contact, account_list: account_list, status: 'Not Interested') }
    let!(:contact_with_no_status) { create(:contact, account_list: account_list, status: nil) }
    let(:contacts) { Contact.all }

    context 'for single status' do
      it 'returns the correct contacts' do
        expect(described_class.query(contacts, { status: 'active' }, nil)).to(
          contain_exactly(active_contact, contact_with_no_status)
        )
        expect(described_class.query(contacts, { status: 'hidden' }, nil)).to(
          contain_exactly(inactive_contact)
        )
        expect(described_class.query(contacts, { status: 'null' }, nil)).to(
          contain_exactly(contact_with_no_status)
        )
        expect(described_class.query(contacts, { status: 'Not Interested' }, nil)).to(
          contain_exactly(inactive_contact)
        )
      end
    end

    context 'for multiple statuses' do
      it 'returns the correct contacts' do
        expect(described_class.query(contacts, { status: 'active, hidden' }, nil)).to(
          contain_exactly(active_contact, inactive_contact, contact_with_no_status)
        )
        expect(described_class.query(contacts, { status: 'hidden, null' }, nil)).to(
          contain_exactly(contact_with_no_status, inactive_contact)
        )
      end
    end

    context 'with reverse_FILTER' do
      subject { described_class.query(contacts, query, nil) }
      let(:query) { { status: status, reverse_status: true } }

      context 'status: "active"' do
        let(:status) { 'active' }
        it('returns hidden contacts') { is_expected.to contain_exactly(inactive_contact) }
      end

      context 'status: "null"' do
        let(:status) { 'null' }
        it('returns hidden contacts') { is_expected.to contain_exactly(inactive_contact) }
      end

      context 'status: "hidden"' do
        let(:status) { 'hidden' }
        it('returns null/blank contacts') { is_expected.to contain_exactly(contact_with_no_status) }
      end
    end
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(
        default_selection: 'active, null',
        multiple: true,
        name: :status,
        options: [{ name: '-- All Active --', id: 'active' },
                  { name: '-- All Hidden --', id: 'hidden' },
                  { name: '-- None --', id: 'null' },
                  { name: 'Never Contacted', id: 'Never Contacted' },
                  { name: 'Ask in Future', id: 'Ask in Future' },
                  { name: 'Cultivate Relationship', id: 'Cultivate Relationship' },
                  { name: 'Contact for Appointment', id: 'Contact for Appointment' },
                  { name: 'Appointment Scheduled', id: 'Appointment Scheduled' },
                  { name: 'Call for Decision', id: 'Call for Decision' },
                  { name: 'Partner - Financial', id: 'Partner - Financial' },
                  { name: 'Partner - Special', id: 'Partner - Special' },
                  { name: 'Partner - Pray', id: 'Partner - Pray' },
                  { name: 'Not Interested', id: 'Not Interested' },
                  { name: 'Unresponsive', id: 'Unresponsive' },
                  { name: 'Never Ask', id: 'Never Ask' },
                  { name: 'Research Abandoned', id: 'Research Abandoned' },
                  { name: 'Expired Referral', id: 'Expired Referral' }],
        parent: nil,
        title: 'Status',
        type: 'multiselect'
      )
    end
  end
end
