require 'rails_helper'

RSpec.describe Api::V2::Tasks::Tags::BulkController, type: :controller do
  let(:resource_type) { :tags }

  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:first_tag)  { 'tag_one' }
  let(:second_tag) { 'tag_two' }

  let(:task_one) { create(:task, account_list: account_list, tag_list: [first_tag]) }
  let(:task_two) { create(:task, account_list: account_list, tag_list: [second_tag]) }

  let(:params) do
    {
      data: [{
        data: {
          type: 'tags',
          attributes: {
            name: first_tag
          }
        }
      }]
    }
  end

  describe '#create' do
    it 'creates the tag object for users that have that access' do
      api_login(user)
      expect do
        post :create, params
      end.to change { task_two.reload.tag_list.length }.by(1)
      expect(response.status).to eq(200)
    end

    context 'with task_ids filter' do
      let(:params) do
        {
          data: [{
            data: {
              type: 'tags',
              attributes: {
                name: first_tag
              }
            }
          }, {
            data: {
              type: 'tags',
              attributes: {
                name: second_tag
              }
            }
          }]
        }
      end

      let(:filter_params) do
        {
          filter: {
            task_ids: task_two.uuid
          }
        }
      end

      it 'applies the tag to the specified tasks' do
        api_login(user)
        expect do
          post :create, params.merge(filter_params)
        end.to change { task_two.reload.tag_list.length }.by(1)
        expect(response.status).to eq(200)
      end

      it 'does not apply the tag to unspecified tasks' do
        api_login(user)
        expect do
          post :create, params.merge(filter_params)
        end.to_not change { task_one.reload.tag_list.length }
        expect(response.status).to eq(200)
      end
    end

    it 'does not create the tag for users that do not own the task' do
      api_login(create(:user_with_account))
      expect do
        post :create, params
      end.not_to change { task_two.reload.tag_list.length }
      expect(response.status).to eq(404)
    end

    it 'does not create the tag object for users that are not signed in' do
      expect do
        post :create, params
      end.not_to change { task_two.reload.tag_list.length }
      expect(response.status).to eq(401)
    end
  end

  describe '#destroy' do
    it 'deletes the resource object for users that have that access' do
      api_login(user)
      expect do
        delete :destroy, params
      end.to change { task_one.reload.tag_list.length }.by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      api_login(create(:user_with_account))
      expect do
        delete :destroy, params
      end.not_to change { task_one.reload.tag_list.length }
      expect(response.status).to eq(404)
    end

    it 'does not delete the resource object for users that are not signed in' do
      expect do
        delete :destroy, params
      end.not_to change { task_one.reload.tag_list.length }
      expect(response.status).to eq(401)
    end
  end
end
