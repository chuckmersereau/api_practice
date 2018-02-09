require 'rails_helper'

RSpec.describe 'Post Requests', type: :request do
  let(:headers) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'Accept'       => 'application/vnd.api+json'
    }
  end

  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }

  describe 'with a related resource' do
    before { api_login(user) }

    context "when the related resource doesn't exist" do
      let!(:new_task_attributes) { attributes_for(:task) }

      let!(:data) do
        {
          data: {
            type: :tasks,
            attributes: new_task_attributes,
            relationships: {
              account_list: {
                data: {
                  id: account_list.id,
                  type: 'account_lists'
                }
              },
              comments: {
                data: [
                  {
                    type: 'comments',
                    id: SecureRandom.uuid
                  }
                ]
              }
            }
          }
        }.to_json
      end

      it 'returns a 404' do
        post api_v2_tasks_path, data, headers
        expect(response.status).to eq(404), invalid_status_detail
      end
    end
  end

  describe 'with a Client Generated UUID' do
    let(:desired_id) { SecureRandom.uuid }
    let(:contact_attributes) { attributes_for(:contact, name: 'Steve Rogers').except!(:id) }

    before { api_login(user) }

    context 'with the UUID in the correct placement: /data/id' do
      let(:post_attributes) do
        {
          data: {
            type: :contacts,
            id: desired_id,
            attributes: contact_attributes,
            relationships: {
              account_list: {
                data: {
                  type: 'account_lists',
                  id: account_list.id
                }
              }
            }
          }
        }.to_json
      end

      it 'creates a resource with the Client Generated UUID' do
        post api_v2_contacts_path, post_attributes, headers

        expect(response.status).to eq(201), invalid_status_detail
        expect(json_response['data']['id']).to eq desired_id
      end
    end

    context 'with the id in: /data/attributes' do
      let(:post_attributes) do
        {
          data: {
            type: :contacts,
            attributes: contact_attributes.merge!(
              id: desired_id
            ),
            relationships: {
              account_list: {
                data: {
                  type: 'account_lists',
                  id: account_list.id
                }
              }
            }
          }
        }.to_json
      end

      let(:error_message) do
        [
          'A primary key, if sent in a request, CANNOT be referenced in the #attributes of a JSONAPI resource object.',
          "It must instead be sent as a top level member of the resource's `data` object. Reference: `/data/attributes/id`. Expected `/data/id`"
        ].join(' ')
      end

      it 'returns an error' do
        post api_v2_contacts_path, post_attributes, headers

        expect(response.status).to eq(409), invalid_status_detail
        expect(json_response['errors'].first['detail']).to eq(error_message)
      end
    end

    context 'with a id that already exists' do
      let!(:pre_existing_task)   { create(:task, account_list: account_list) }
      let!(:new_task_attributes) { attributes_for(:task) }

      let!(:data) do
        {
          data: {
            id: pre_existing_task.id,
            type: :tasks,
            attributes: new_task_attributes,
            relationships: {
              account_list: {
                data: {
                  type: 'account_lists',
                  id: account_list.id
                }
              }
            }
          }
        }.to_json
      end

      it 'returns a 409' do
        post api_v2_tasks_path, data, headers
        expect(response.status).to eq(409), invalid_status_detail
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
            attributes: new_task_attributes,
            relationships: {
              account_list: {
                data: {
                  type: 'account_lists',
                  id: account_list.id
                }
              }
            }
          }
        }.to_json
      end

      it 'returns a 201' do
        post api_v2_tasks_path, data, headers

        expect(response.status).to eq(201), invalid_status_detail
        expect(json_response['errors']).to be_nil
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
              account_list_id: account_list.id
            )
          }
        }.to_json
      end

      let(:error_message) do
        "'gummybear' is not a valid resource type for this endpoint. Expected 'tasks' instead"
      end

      it 'returns a 409' do
        post api_v2_tasks_path, data, headers

        expect(response.status).to eq(409), invalid_status_detail
        expect(json_response['errors'].first['title']).to eq('Conflict')
        expect(json_response['errors'].first['detail']).to eq(error_message)
      end
    end

    context 'when the resource type is missing' do
      let!(:new_task_attributes) { attributes_for(:task) }

      let!(:data) do
        {
          data: {
            type: nil, # missing type
            attributes: new_task_attributes,
            relationships: {
              account_list: {
                data: {
                  type: 'account_lists',
                  id: account_list.id
                }
              }
            }
          }
        }.to_json
      end

      let(:error_message) do
        'JSONAPI resource objects MUST contain a `type` top-level member of its hash for POST and PATCH requests. Expected to find a `type` member at /data/type'
      end

      it 'returns a 409' do
        post api_v2_tasks_path, data, headers

        expect(response.status).to eq(409), invalid_status_detail
        expect(json_response['errors'].first['title']).to eq('Conflict')
        expect(json_response['errors'].first['detail']).to eq(error_message)
      end
    end
  end
end
