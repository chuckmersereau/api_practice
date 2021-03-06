require 'rails_helper'

RSpec.describe Api::V2::AppealsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:factory_type) { :appeal }

  let!(:resource) { create(:appeal, account_list: account_list) }
  let!(:second_resource) { create(:appeal, account_list: account_list) }
  let(:id) { resource.id }

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
          id: account_list.id
        }
      }
    }
  end

  let(:unpermitted_relationships) do
    {
      account_list: {
        data: {
          type: 'account_lists',
          id: create(:account_list).id
        }
      }
    }
  end

  before do
    resource.contacts << create(:contact, account_list: account_list) # Test inclusion of related resources.
  end

  include_examples 'create_examples'

  include_examples 'show_examples'

  include_examples 'update_examples'

  include_examples 'destroy_examples'

  include_examples 'index_examples'

  describe '#index' do
    before { api_login(user) }

    describe 'filter[account_list_id]' do
      let!(:first_account_list) { account_list }
      let!(:second_account_list) { create(:account_list) }
      let!(:appeal_for_second_account_list) { create(:appeal, account_list: second_account_list) }

      before do
        user.account_lists << second_account_list
      end

      it 'returns appeals from multiple accounts lists when not filtering' do
        get :index
        data = JSON.parse(response.body)['data']
        expect(data.size).to eq(3)
        ids = data.map { |d| d['id'] }
        expect(ids).to contain_exactly(resource.id,
                                       second_resource.id,
                                       appeal_for_second_account_list.id)
      end

      it 'returns appeals from one account list when filtering' do
        get :index, filter: { account_list_id: first_account_list.id }
        data = JSON.parse(response.body)['data']
        expect(data.size).to eq(2)
        ids = data.map { |d| d['id'] }
        expect(ids).to contain_exactly(resource.id,
                                       second_resource.id)
      end

      it "includes the donation's contact when filtering" do
        donor_account = create(:donor_account)
        contact = create(:contact, account_list: account_list)
        donor_account.contacts << contact
        donation = create(:donation, donor_account: donor_account)
        resource.donations << donation

        get :index, include: 'donations.contacts', filter: { account_list_id: first_account_list.id }
        body = JSON.parse(response.body)
        expect(body['included'].first['id']).to eq(donation.id)
        expect(body['included'].first['relationships']['contact']['data']['id']).to eq(contact.id)
      end

      it "does not permit filtering by an account list that's not owned by current user" do
        not_my_account_list = create(:account_list)
        get :index, filter: { account_list_id: not_my_account_list.id }
        expect(response.code).to eq('403')
      end
    end

    describe 'filter[wildcard_search]' do
      context 'name contains' do
        let!(:appeal) { create(factory_type, name: 'abcd', account_list: account_list) }

        it 'returns appeal' do
          get :index, filter: { wildcard_search: 'bc' }
          expect(JSON.parse(response.body)['data'][0]['id']).to eq(appeal.id)
        end
      end

      context 'name does not contain' do
        let!(:appeal) { create(factory_type, name: 'abcd', account_list: account_list) }

        it 'returns no appeals' do
          get :index, filter: { wildcard_search: 'def' }
          expect(JSON.parse(response.body)['data'].count).to eq(0)
        end
      end
    end
  end
end
