require 'rails_helper'

RSpec.describe Api::V2::Tasks::Tags::BulkController, type: :controller do
  let(:resource_type) { :tags }

  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:first_tag) { 'tag_one' }
  let(:second_tag) { 'tag_two' }
  let(:task_one) { create(:task, account_list: account_list, tag_list: [first_tag]) }
  let(:task_two) { create(:task, account_list: account_list, tag_list: [second_tag]) }

  describe '#destroy' do
    it 'deletes the resource object for users that have that access' do
      api_login(user)
      expect do
        delete :destroy, tag_name: first_tag
      end.to change { task_one.reload.tag_list.length }.by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      api_login(create(:user_with_account))
      expect do
        delete :destroy, tag_name: first_tag
      end.not_to change { task_one.reload.tag_list.length }
      expect(response.status).to eq(404)
    end

    it 'does not delete the resource object for users that are not signed in' do
      expect do
        delete :destroy, tag_name: first_tag
      end.not_to change { task_one.reload.tag_list.length }
      expect(response.status).to eq(401)
    end
  end
end
