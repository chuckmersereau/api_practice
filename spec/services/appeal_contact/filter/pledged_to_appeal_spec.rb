require 'rails_helper'

RSpec.describe AppealContact::Filter::PledgedToAppeal do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:appeal) { create(:appeal, account_list: account_list) }

  let!(:no_appeal_contact) { create(:contact, account_list_id: account_list.id) }
  let!(:not_pledged_contact) { create(:contact, account_list_id: account_list.id) }
  let!(:pledged_contact) { create(:contact, account_list_id: account_list.id) }

  before do
    not_pledged_contact.appeals << appeal
    pledged_contact.appeals << appeal
    pledged_contact.pledges << create(:pledge, account_list: account_list, appeal: appeal)
  end

  describe '#query' do
    let(:appeal_contacts) { AppealContact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(appeal_contacts, {}, nil)).to eq(nil)
        expect(described_class.query(appeal_contacts, { pledged_to_appeal: '', appeal_id: appeal.id }, nil)).to eq(nil)
      end
    end

    context 'filter by not pledged_to_appeal' do
      it 'returns only contacts that have not pledged' do
        filtered = described_class.query(appeal_contacts, { pledged_to_appeal: false, appeal_id: appeal.id }, nil).to_a
        expect(filtered.collect(&:contact)).to match_array [not_pledged_contact]
      end
    end

    context 'filter by pledged_to_appeal' do
      it 'returns only contacts that have pledged' do
        filtered = described_class.query(appeal_contacts, { pledged_to_appeal: true, appeal_id: appeal.id }, nil).to_a
        expect(filtered.collect(&:contact)).to match_array [pledged_contact]
      end
    end
  end
end
