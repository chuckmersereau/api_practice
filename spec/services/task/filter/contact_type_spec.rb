require 'rails_helper'

RSpec.describe Task::Filter::ContactType do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list: account_list) }
  let!(:contact_two) { create(:contact, account_list: account_list) }

  let!(:task_one) { create(:task, account_list: account_list, contacts: [contact_one]) }
  let!(:task_two) { create(:task, account_list: account_list, contacts: [contact_two]) }

  let!(:person_one) { create(:person) }
  let!(:donor_account) { create(:donor_account, master_company: create(:master_company)) }

  before do
    contact_one.people << person_one
    contact_two.donor_accounts << donor_account
  end

  describe '#query' do
    let(:tasks) { account_list.tasks }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(tasks, {}, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_type: {} }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_type: [] }, account_list)).to eq(nil)
        expect(described_class.query(tasks, { contact_type: '' }, account_list)).to eq(nil)
      end
    end

    context 'filter tasks by contact type person' do
      it 'returns tasks with contacts that are the correct type' do
        expect(described_class.query(tasks, { contact_type: 'person' }, account_list).to_a).to eq [task_one]
      end
    end
    context 'filter tasks by contact type company' do
      it 'returns tasks with contacts that are the correct type' do
        expect(described_class.query(tasks, { contact_type: 'company' }, account_list).to_a).to eq [task_two]
      end
    end
  end
end
