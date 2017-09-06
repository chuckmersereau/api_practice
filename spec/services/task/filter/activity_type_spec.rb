require 'rails_helper'

RSpec.describe Task::Filter::ActivityType do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }

  let!(:task_one)   { create(:task, account_list: account_list, activity_type: 'Call') }
  let!(:task_two)   { create(:task, account_list: account_list, activity_type: 'Appointment') }
  let!(:task_three) { create(:task, account_list: account_list, activity_type: 'Email') }
  let!(:task_four)  { create(:task, account_list: account_list, activity_type: nil) }
  let!(:task_five)  { create(:task, account_list: account_list, activity_type: '') }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: true,
                                                                name: :activity_type,
                                                                options: [
                                                                  { name: '-- Any --', id: '', placeholder: 'None' },
                                                                  { name: '-- None --', id: 'none' },
                                                                  { name: 'Call', id: 'Call' },
                                                                  { name: 'Appointment', id: 'Appointment' },
                                                                  { name: 'Email', id: 'Email' },
                                                                  { name: 'Text Message', id: 'Text Message' },
                                                                  { name: 'Facebook Message', id: 'Facebook Message' },
                                                                  { name: 'Letter', id: 'Letter' },
                                                                  { name: 'Newsletter - Physical', id: 'Newsletter - Physical' },
                                                                  { name: 'Newsletter - Email', id: 'Newsletter - Email' },
                                                                  { name: 'Pre Call Letter', id: 'Pre Call Letter' },
                                                                  { name: 'Reminder Letter', id: 'Reminder Letter' },
                                                                  { name: 'Support Letter', id: 'Support Letter' },
                                                                  { name: 'Thank', id: 'Thank' },
                                                                  { name: 'To Do', id: 'To Do' },
                                                                  { name: 'Talk to In Person', id: 'Talk to In Person' },
                                                                  { name: 'Prayer Request', id: 'Prayer Request' }
                                                                ],
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
        expect(described_class.query(tasks, { activity_type: 'Call, Appointment,none' }, nil).to_a).to match_array([task_one, task_two, task_four, task_five])
        expect(described_class.query(tasks, { activity_type: 'call,none, Email,' }, nil).to_a).to match_array([task_three, task_four, task_five])
      end
      it 'filters a single activity_type' do
        expect(described_class.query(tasks, { activity_type: 'Email' }, nil).to_a).to match_array([task_three])
      end
      it 'filters by non existing activity_type' do
        expect(described_class.query(tasks, { activity_type: 'Newsletter' }, nil).to_a).to eq([])
      end
      it 'filters by none' do
        expect(described_class.query(tasks, { activity_type: 'none' }, nil).to_a).to match_array([task_four, task_five])
      end
    end
  end
end
