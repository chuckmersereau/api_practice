require 'rails_helper'

RSpec.describe Task::Filter::ContactStatus do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let!(:active_contact) { create(:contact, account_list: account_list, status: 'Ask in Future') }
  let!(:inactive_contact) { create(:contact, account_list: account_list, status: 'Not Interested') }
  let!(:contact_with_no_status) { create(:contact, account_list: account_list, status: nil) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [active_contact]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [inactive_contact]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_with_no_status]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'for single status' do
      it 'returns the correct tasks for corresponding contact status filter' do
        expect(described_class.query(tasks, { contact_status: 'active' }, account_list).to_a).to(
          contain_exactly(task_one, task_three)
        )
        expect(described_class.query(tasks, { contact_status: 'hidden' }, account_list).to_a).to(
          contain_exactly(task_two)
        )
        expect(described_class.query(tasks, { contact_status: 'null' }, account_list).to_a).to(
          contain_exactly(task_three)
        )
        expect(described_class.query(tasks, { contact_status: 'null' }, account_list).to_a).not_to(
          contain_exactly(task_one, task_two, task_three)
        )
      end
    end

    context 'for multiple statuses' do
      it 'returns the correct contacts' do
        expect(described_class.query(tasks, { contact_status: 'active, hidden' }, account_list).to_a).to(
          contain_exactly(task_one, task_two, task_three)
        )
        expect(described_class.query(tasks, { contact_status: 'hidden, null' }, account_list).to_a).to(
          contain_exactly(task_two, task_three)
        )
        expect(described_class.query(tasks, { contact_status: 'null, hidden' }, account_list).to_a).not_to(
          contain_exactly(task_one, task_two, task_three)
        )
      end
    end

    context 'with reverse_FILTER' do
      subject { described_class.query(tasks, query, account_list) }
      let(:query) { { contact_status: contact_status, reverse_contact_status: true } }

      context 'contact_status: "active"' do
        let(:contact_status) { 'active' }
        it('returns tasks owned by hidden contacts') { is_expected.to match_array([task_two]) }
      end

      context 'contact_status: "null"' do
        let(:contact_status) { 'null' }
        it('returns tasks owned by hidden contacts') { is_expected.to match_array([task_two]) }
      end

      context 'contact_status: "hidden"' do
        let(:contact_status) { 'hidden' }
        it('returnstasks owned by  null/blank contacts') { is_expected.to match_array([task_three]) }
      end
    end
  end
end
