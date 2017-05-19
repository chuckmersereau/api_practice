require 'rails_helper'

RSpec.describe Api::V2::AppealsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :appeal }

  let!(:resource) { create(:appeal, account_list: account_list) }
  let!(:second_resource) { create(:appeal, account_list: account_list) }
  let(:id) { resource.uuid }

  let(:correct_attributes) { attributes_for(:appeal, name: 'Appeal 2') }
  let(:unpermitted_attributes) { attributes_for(:appeal, name: 'Appeal 3') }
  let(:incorrect_attributes) { attributes_for(:appeal, name: nil) }

  let(:given_update_reference_key)   { :name }
  let(:given_update_reference_value) { 'Appeal 2' }

  let(:correct_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: account_list.uuid
        }
      }
    }
  end

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).uuid
        }
      }
    }
  end

  before do
    resource.contacts << create(:contact) # Test inclusion of related resources.
  end

  include_examples 'create_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe '#index' do
    before { api_login(user) }
    let(:account_list_id) { account_list.id }
    describe 'filter[wildcard_search]' do
      context 'name contains' do
        let!(:appeal) { create(factory_type, name: 'abcd', account_list: account_list) }
        it 'returns appeal' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: 'bc' }
          expect(JSON.parse(response.body)['data'][0]['id']).to eq(appeal.uuid)
        end
      end
      context 'name does not contain' do
        let!(:appeal) { create(factory_type, name: 'abcd', account_list: account_list) }
        it 'returns no appeals' do
          get :index, account_list_id: account_list_id, filter: { wildcard_search: 'def' }
          expect(JSON.parse(response.body)['data'].count).to eq(0)
        end
      end
    end
  end
end
