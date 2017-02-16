require 'rails_helper'

describe Api::V2::Contacts::Merges::BulkController, type: :controller do
  let!(:account_list)              { user.account_lists.first }
  let!(:account_list_id)           { account_list.uuid }
  let!(:correct_attributes)        { attributes_for(:contact, name: 'Michael Bluth', account_list_id: account_list_id, tag_list: 'tag1') }
  let!(:factory_type)              { :contact }
  let!(:id)                        { resource.uuid }
  let!(:incorrect_attributes)      { attributes_for(:contact, name: nil, account_list_id: account_list_id) }
  let!(:resource)                  { create(:contact_with_person, account_list: account_list) }
  let!(:second_resource)           { create(:contact, account_list: account_list) }
  let!(:third_resource)            { create(:contact, account_list: account_list) }
  let!(:fourth_resource)           { create(:contact, account_list: account_list) }
  let(:winner_id)                  { resource.uuid }
  let(:loser_id)                   { second_resource.uuid }
  let(:first_merge_attributes)     { { winner_id: winner_id, loser_id: loser_id } }
  let(:second_merge_attributes)    { { winner_id: third_resource.uuid, loser_id: fourth_resource.uuid } }
  let!(:user)                      { create(:user_with_account) }

  describe '#create' do
    let(:unauthorized_resource) { create(factory_type) }
    let(:bulk_create_attributes) do
      { data: [
        { data: { attributes: first_merge_attributes } },
        { data: { attributes: second_merge_attributes } }
      ] }
    end
    let(:response_body) { JSON.parse(response.body) }
    let(:response_errors) { response_body['errors'] }

    before do
      api_login(user)
    end

    it 'returns a 200 and the list of updated resources' do
      post :create, bulk_create_attributes
      expect(response.status).to eq(200)
      expect(response_body.length).to eq(2)
    end

    context 'when the user is unauthorized to perform one of the merges' do
      let(:second_resource) { create(:contact) }

      it 'returns a 200 and only performs the authorized merge' do
        post :create, bulk_create_attributes
        expect(response.status).to eq(200)
        expect(response_body.length).to eq(1)
      end
    end

    context 'when one of the contacts in one of the merges is non-existant' do
      let(:winner_id) { SecureRandom.uuid }

      it 'returns a 200 and skips the errant merge' do
        post :create, bulk_create_attributes
        expect(response.status).to eq(200)
        expect(response_body.length).to eq(1)
      end

      context 'and there is only one merge being performed' do
        let(:bulk_create_attributes) do
          { data: [
            { data: { attributes: first_merge_attributes } }
          ] }
        end

        it 'returns a 404' do
          post :create, bulk_create_attributes
          expect(response.status).to eq(404)
        end
      end
    end
  end
end
