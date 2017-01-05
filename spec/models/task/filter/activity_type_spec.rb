require 'spec_helper'

RSpec.describe Task::Filter::ActivityType do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list: account_list, activity_type: 'Call') }
  let!(:task_two)   { create(:task, account_list: account_list, activity_type: 'Appointment') }
  let!(:task_three) { create(:task, account_list: account_list, activity_type: 'Email') }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :activity_type,
                                                                options: [
                                                                  { name: '-- Any --', id: '', placeholder: 'None' },
                                                                  { name: 'Call', id: 'Call' },
                                                                  { name: 'Appointment', id: 'Appointment' },
                                                                  { name: 'Email', id: 'Email' },
                                                                  { name: 'Text Message', id: 'Text Message' },
                                                                  { name: 'Facebook Message', id: 'Facebook Message' },
                                                                  { name: 'Letter', id: 'Letter' },
                                                                  { name: 'Newsletter', id: 'Newsletter' },
                                                                  { name: 'Pre Call Letter', id: 'Pre Call Letter' },
                                                                  { name: 'Reminder Letter', id: 'Reminder Letter' },
                                                                  { name: 'Support Letter', id: 'Support Letter' },
                                                                  { name: 'Thank', id: 'Thank' },
                                                                  { name: 'To Do', id: 'To Do' },
                                                                  { name: 'Talk to In Person', id: 'Talk to In Person' },
                                                                  { name: 'Prayer Request', id: 'Prayer Request' }],
                                                                parent: nil,
                                                                priority: 0,
                                                                title: 'Action',
                                                                type: 'multiselect',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, nil)).to eq(nil)
        expect(described_class.query(tasks, { activity_type: {} }, nil)).to eq(nil)
        expect(described_class.query(tasks, { activity_type: [] }, nil)).to eq(nil)
        expect(described_class.query(tasks, { activity_type: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by activity_type' do
      it 'filters multiple activity_types' do
        expect(described_class.query(tasks, { activity_type: %w(Call Appointment) }, nil).to_a).to include(task_one, task_two)
      end
      it 'filters a single activity_type' do
        expect(described_class.query(tasks, { activity_type: 'Email' }, nil).to_a).to include(task_three)
      end
      it 'filters by non existing activity_type' do
        expect(described_class.query(tasks, { activity_type: 'Newsletter' }, nil).to_a).to be_empty
      end
    end
  end
end
