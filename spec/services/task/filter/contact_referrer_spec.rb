require 'rails_helper'

RSpec.describe Task::Filter::ContactReferrer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let!(:contact_one) { create(:contact, account_list: account_list) }
  let!(:contact_two) { create(:contact, account_list: account_list) }
  let!(:contact_three) { create(:contact, account_list: account_list) }
  let!(:contact_four) { create(:contact, account_list: account_list) }

  before do
    ContactReferral.create! referred_by: contact_one, referred_to: contact_two
  end

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }
  let!(:task_three) { create(:task, account_list: account_list, contacts: [contact_three]) }
  let!(:task_four) { create(:task, account_list: account_list, contacts: [contact_four]) }

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { referrer: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { referrer: [] }, account_list)).to eq(nil)
      end
    end

    context 'task filter by no contact referrer' do
      it 'only returns tasks with contacts that have no referrer' do
        expect(described_class.query(tasks, { contact_referrer: 'none' }, account_list).to_a).to match_array [task_one, task_three, task_four]
      end
    end

    context 'task filter by any contact referrer' do
      it 'only returns tasks with contacts that have any referrer' do
        expect(described_class.query(tasks, { contact_referrer: 'any' }, account_list).to_a).to match_array [task_two]
      end
    end

    context 'task filter by  referrer' do
      it 'filters tasks with contacts that have a single referrer' do
        expect(described_class.query(tasks, { contact_referrer: contact_one.uuid.to_s }, account_list).to_a).to match_array [task_two]
      end

      it 'filters tasks with contacts that have multiple referrers' do
        expect(described_class.query(tasks, { contact_referrer: "#{contact_one.uuid}, #{contact_one.uuid}" }, account_list).to_a).to match_array [task_two]
      end
    end

    context 'task filter by multiple filters' do
      it 'returns tasks matching multiple filters' do
        expect(described_class.query(tasks, { contact_referrer: "#{contact_one.uuid}, none" }, account_list).to_a).to match_array [task_one, task_two, task_three, task_four]
      end
    end
  end
end
