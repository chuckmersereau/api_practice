require 'spec_helper'

RSpec.describe 'Post Requests', type: :request do
  let(:headers) { { 'CONTENT_TYPE' => 'application/vnd.api+json' } }

  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  let(:json_data) { JSON.parse(response.body) }

  describe 'with a related resource' do
    before { api_login(user) }

    context "when the related resource doesn't exist" do
      let!(:new_task_attributes) { attributes_for(:task) }

      let!(:data) do
        {
          data: {
            type: :tasks,
            attributes: new_task_attributes.merge!(
              account_list_id: 'non-existant-UUID'
            )
          }
        }.to_json
      end

      it 'returns a 404' do
        post api_v2_tasks_path, data, headers
        expect(response.status).to eq 404
      end
    end
  end

  describe 'with a Client Generated UUID' do
    let(:desired_uuid)       { SecureRandom.uuid }
    let(:contact_attributes) { attributes_for(:contact, name: 'Steve Rogers') }

    before { api_login(user) }

    context 'with the UUID in the correct placement: /data/id' do
      let(:post_attributes) do
        {
          data: {
            type: :contacts,
            id: desired_uuid,
            attributes: contact_attributes.merge!(
              account_list_id: account_list.uuid
            )
          }
        }.to_json
      end

      it 'creates a resource with the Client Generated UUID' do
        post api_v2_contacts_path, post_attributes, headers

        expect(response.status).to eq 201
        expect(json_data['data']['id']).to eq desired_uuid
      end
    end

    context 'with the UUID in: /data/attributes' do
      let(:post_attributes) do
        {
          data: {
            type: :contacts,
            attributes: contact_attributes.merge!(
              id: desired_uuid,
              account_list_id: account_list.uuid
            )
          }
        }.to_json
      end

      let(:error_message) do
        'A primary `id` cannot be sent at `/data/attributes/id`, it must be sent at `/data/id`'
      end

      it 'returns an error' do
        post api_v2_contacts_path, post_attributes, headers

        expect(response.status).to eq 403
        expect(json_data['errors'].first['title']).to eq(error_message)
      end
    end

    context 'with a UUID that already exists' do
      let!(:pre_existing_task)   { create(:task, account_list: account_list) }
      let!(:new_task_attributes) { attributes_for(:task) }

      let!(:data) do
        {
          data: {
            id: pre_existing_task.uuid,
            type: :tasks,
            attributes: new_task_attributes.merge!(
              account_list_id: account_list.uuid
            )
          }
        }.to_json
      end

      it 'returns a 409' do
        post api_v2_tasks_path, data, headers
        expect(response.status).to eq 409
      end
    end
  end

  describe 'creating a resource with a specified type' do
    before { api_login(user) }

    context 'when the resource type is correct' do
      let!(:new_task_attributes) { attributes_for(:task) }
      let!(:valid_type)          { :tasks }

      let!(:data) do
        {
          data: {
            type: valid_type,
            attributes: new_task_attributes.merge!(
              account_list_id: account_list.uuid
            )
          }
        }.to_json
      end

      it 'returns a 409' do
        post api_v2_tasks_path, data, headers

        expect(response.status).to eq 201
        expect(json_data['errors']).to be_nil
      end
    end

    context 'when the resource type is incorrect' do
      let!(:new_task_attributes) { attributes_for(:task) }
      let!(:invalid_type)        { :gummybear }

      let!(:data) do
        {
          data: {
            type: invalid_type,
            attributes: new_task_attributes.merge!(
              account_list_id: account_list.uuid
            )
          }
        }.to_json
      end

      let(:error_message) do
        "'gummybear' is not a valid resource type for this endpoint. Expected 'tasks' instead"
      end

      it 'returns a 409' do
        post api_v2_tasks_path, data, headers

        expect(response.status).to eq 409
        expect(json_data['errors'].first['title']).to eq('Conflict')
        expect(json_data['errors'].first['detail']).to eq(error_message)
      end
    end
  end
end
