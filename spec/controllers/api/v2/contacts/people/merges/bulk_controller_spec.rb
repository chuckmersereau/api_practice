require 'rails_helper'

describe Api::V2::Contacts::People::Merges::BulkController, type: :controller do
  let!(:account_list)              { user.account_lists.first }
  let!(:account_list_id)           { account_list.id }
  let!(:correct_attributes)        { attributes_for(:contact, name: 'Michael Bluth', account_list_id: account_list_id, tag_list: 'tag1') }
  let!(:factory_type)              { :contact }
  let!(:id)                        { resource.id }
  let!(:incorrect_attributes)      { attributes_for(:contact, name: nil, account_list_id: account_list_id) }
  let!(:contact)                   { create(:contact, account_list: account_list) }
  let!(:resource)                  { create(:person, contacts: [contact]) }
  let!(:second_resource)           { create(:person, contacts: [contact]) }
  let!(:third_resource)            { create(:person, contacts: [contact]) }
  let!(:fourth_resource)           { create(:person, contacts: [contact]) }
  let(:winner_id)                  { resource.id }
  let(:loser_id)                   { second_resource.id }
  let(:first_merge_attributes)     { { winner_id: winner_id, loser_id: loser_id } }
  let(:second_merge_attributes)    { { winner_id: third_resource.id, loser_id: fourth_resource.id } }
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
      let(:second_resource) { create(:person) }

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
