require 'spec_helper'
require 'support/shared_controller_examples'

RSpec.describe Api::V2::Tasks::TagsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:first_tag) { 'tag_one' }
  let(:task) { create(:task, account_list: user.account_lists.first, tag_list: [first_tag]) }
  let(:second_tag) { 'tag_two' }
  let(:correct_attributes) { { name: second_tag } }
  let(:incorrect_attributes) { { name: nil } }
  let(:full_correct_attributes) { { task_id: task.id, data: { attributes: correct_attributes } } }
  let(:full_incorrect_attributes) { { task_id: task.id, data: { attributes: incorrect_attributes } } }

  describe '#create' do
    it 'creates resource for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change { task.reload.tag_list.length }.by(1)
      expect(response.status).to eq(201)
    end

    it 'does not create the resource when there are errors in sent data' do
      api_login(user)
      expect do
        post :create, full_incorrect_attributes
      end.not_to change { task.reload.tag_list.length }
      expect(response.status).to eq(400)
      expect(response.body).to include('errors')
      expect(task.reload.tag_list).to_not include(second_tag)
    end

    it 'does not create resource for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
      end.not_to change { task.reload.tag_list.length }
      expect(response.status).to eq(401)
      expect(task.reload.tag_list).to_not include(second_tag)
    end
  end

  describe '#destroy' do
    it 'deletes the resource object for users that have that access' do
      api_login(user)
      expect do
        delete :destroy, task_id: task.id, tag_name: first_tag
      end.to change { task.reload.tag_list.length }.by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      api_login(create(:user))
      expect do
        delete :destroy, task_id: task.id, tag_name: second_tag
      end.not_to change { task.tag_list.length }
      expect(response.status).to eq(403)
    end

    it 'does not delete the resource object for users that are not signed in' do
      expect do
        delete :destroy, task_id: task.id, tag_name: second_tag
      end.not_to change { task.tag_list.length }
      expect(response.status).to eq(401)
    end
  end
end
