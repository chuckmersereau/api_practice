require 'rails_helper'

describe Api::V2::Appeals::ExcludedAppealContactsController, type: :controller do
  let(:factory_type) { :appeal_excluded_appeal_contact }
  let!(:user) { create(:user_with_full_account) }
  let!(:account_list) { user.account_lists.first }
  let(:account_list_id) { account_list.uuid }
  let!(:appeal) { create(:appeal, account_list: account_list) }
  let(:appeal_id) { appeal.uuid }
  let!(:contact) { create(:contact, account_list: account_list) }
  let!(:excluded_appeal_contact) { create(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact) }
  let!(:second_contact) { create(:contact, account_list: account_list) }
  let!(:second_excluded_appeal_contact) do
    create(:appeal_excluded_appeal_contact, appeal: appeal, contact: second_contact)
  end
  let(:id) { excluded_appeal_contact.uuid }

  let(:resource) { excluded_appeal_contact }
  let(:parent_param) { { appeal_id: appeal_id } }
  let(:correct_attributes) { {} }

  include_examples 'index_examples'
  include_examples 'show_examples'

  describe 'sorting' do
    before { api_login(user) }

    context 'contact.name sort' do
      let!(:sorting_appeal) { create(:appeal, account_list: account_list) }
      let!(:contact1) { create(:contact, account_list: account_list, name: 'Currie, Marie') }
      let!(:contact2) { create(:contact, account_list: account_list, name: 'Einstein, Albert') }
      let!(:excluded_appeal_contact1) do
        create(:appeal_excluded_appeal_contact, contact: contact1, appeal: sorting_appeal)
      end
      let!(:excluded_appeal_contact2) do
        create(:appeal_excluded_appeal_contact, contact: contact2, appeal: sorting_appeal)
      end

      it 'sorts results desc' do
        get :index, appeal_id: sorting_appeal.uuid, sort: 'contact.name'
        expect(response.status).to eq(200)
        data = JSON.parse(response.body)['data']
        expect(data.length).to eq(2)
        expect(data[0]['id']).to eq(excluded_appeal_contact1.uuid)
        expect(data[1]['id']).to eq(excluded_appeal_contact2.uuid)
      end

      it 'sorts results asc' do
        get :index, appeal_id: sorting_appeal.uuid, sort: '-contact.name'
        expect(response.status).to eq(200)
        data = JSON.parse(response.body)['data']
        expect(data.length).to eq(2)
        expect(data[0]['id']).to eq(excluded_appeal_contact2.uuid)
        expect(data[1]['id']).to eq(excluded_appeal_contact1.uuid)
      end
    end
  end
end
