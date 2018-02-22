require 'rails_helper'

RSpec.describe Contact::Filter::TaskDueDate do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two) { create(:contact, account_list_id: account_list.id) }
  let!(:activity_one) { create(:activity, account_list: account_list, start_at: 1.month.ago) }
  let!(:activity_two) { create(:activity, account_list: account_list, start_at: 1.month.from_now) }

  before do
    contact_one.activities << activity_one
    contact_two.activities << activity_two
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list]).except(:options)).to include(
        default_selection: '',
        multiple: false,
        name: :task_due_date,
        parent: 'Tasks',
        title: 'Due Date',
        type: 'daterange'
      )
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { task_due_date: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { task_due_date: { wut: '???', hey: 'yo' } }, nil)).to eq(nil)
        expect(described_class.query(contacts, { task_due_date: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by end and start date' do
      it 'returns only contacts with a task due after the start date and before the end date' do
        expect(described_class.query(contacts, { task_due_date: Range.new(1.year.ago, 1.year.from_now) }, nil).to_a).to match_array [contact_one, contact_two]
        expect(described_class.query(contacts, { task_due_date: Range.new(1.day.ago, 2.months.from_now) }, nil).to_a).to eq [contact_two]
      end
    end
  end
end
