require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::Contacts::TagsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:first_tag) { 'tag_one' }
  let(:second_tag) { 'tag_two' }
  let(:contact) { create(:contact, account_list: account_list, tag_list: [first_tag]) }
  let(:correct_attributes) { { name: second_tag } }
  let(:incorrect_attributes) { { name: nil } }
  let(:full_correct_attributes) { { contact_id: contact.uuid, data: { attributes: correct_attributes } } }
  let(:full_incorrect_attributes) { { contact_id: contact.uuid, data: { attributes: incorrect_attributes } } }

  describe '#index' do
    let!(:account_list_two) { create(:account_list) }
    let!(:contact_one) { create(:contact, account_list: account_list, tag_list: [first_tag]) }
    let!(:contact_two) { create(:contact, account_list: account_list_two, tag_list: [second_tag]) }
    before { user.account_lists << account_list_two }
    it 'lists resources for users that are signed in' do
      api_login(user)
      get :index
      expect(JSON.parse(response.body)['data'].length).to eq 2
      expect(JSON.parse(response.body)['data'][0]['attributes']['name']).to eq first_tag
      expect(JSON.parse(response.body)['data'][1]['attributes']['name']).to eq second_tag
      expect(response.status).to eq(200)
    end

    it 'does not list resources for users that are not signed in' do
      get :index
      expect(response.status).to eq(401)
    end

    context 'account_list_id filter' do
      it 'filters results' do
        api_login(user)
        get :index, filter: { account_list_id: account_list_two.uuid }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data'].length).to eq(1)
        expect(JSON.parse(response.body)['data'][0]['attributes']['name']).to eq(second_tag)
      end
    end
  end

  describe '#create' do
    it 'creates resource for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change { contact.reload.tag_list.length }.by(1)
      expect(response.status).to eq(201)
    end

    it 'does not create the resource when there are errors in sent data' do
      api_login(user)
      expect do
        post :create, full_incorrect_attributes
      end.not_to change { contact.reload.tag_list.length }
      expect(response.status).to eq(400)
      expect(response.body).to include('errors')
      expect(contact.reload.tag_list).to_not include(second_tag)
    end

    it 'does not create resource for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
      end.not_to change { contact.reload.tag_list.length }
      expect(response.status).to eq(401)
      expect(contact.reload.tag_list).to_not include(second_tag)
    end
  end

  describe '#destroy' do
    it 'deletes the resource object for users that have that access' do
      api_login(user)
      expect do
        delete :destroy, contact_id: contact.uuid, tag_name: first_tag
      end.to change { contact.reload.tag_list.length }.by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      api_login(create(:user))
      expect do
        delete :destroy, contact_id: contact.uuid, tag_name: second_tag
      end.not_to change { contact.tag_list.length }
      expect(response.status).to eq(403)
    end

    it 'does not delete the resource object for users that are not signed in' do
      expect do
        delete :destroy, contact_id: contact.uuid, tag_name: second_tag
      end.not_to change { contact.tag_list.length }
      expect(response.status).to eq(401)
    end
  end
end
