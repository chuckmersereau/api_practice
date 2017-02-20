# coding: utf-8
require 'uuidtools'
require 'rails_helper'

RSpec.describe 'Patch Requests', type: :request do
  let!(:user)   { create(:user_with_account) }
  let(:contact) { create(:contact) }

  let(:headers) do
    {
      'CONTENT_TYPE' => 'application/vnd.api+json',
      'ACCEPT' => 'application/vnd.api+json'
    }
  end

  let(:update_attributes) { { first_name: 'test_first_name' } }

  let(:full_update_attributes) do
    {
      data: {
        type: 'users',
        attributes: update_attributes.merge(updated_in_db_at: user.updated_at)
      }
    }
  end

  before { api_login(user) }

  describe 'requests' do
    context 'with correct parameters (200)' do
      it 'should return a success status (200)' do
        put api_v2_user_path, full_update_attributes.to_json, headers
        expect(response.status).to eq(200), invalid_status_detail
      end

      it 'should return a representation of the updated resource' do
        put api_v2_user_path, full_update_attributes.to_json, headers
        updated_user_first_name = JSON.parse(response.body)['data']['attributes']['first_name']
        expect(updated_user_first_name).to eq('test_first_name')
      end
    end

    context 'with unsupported/forbidden parameters (403)' do
      let(:account_list) { user.account_lists.first }
      let(:id) { account_list.uuid }
      let(:update_attributes) { attributes_for(:account_list) }
      let(:full_update_attributes) do
        {
          data: {
            id: account_list.uuid,
            type: 'account_lists',
            attributes: update_attributes.merge(updated_in_db_at: account_list.updated_at)
          }
        }
      end

      it 'should return a forbidden status (403)' do
        api_login(create(:user))
        put api_v2_account_list_path(id), full_update_attributes.to_json, headers
        expect(response.status).to eq(403), invalid_status_detail
      end
    end

    context 'against a resource that does not exist (404)' do
      let(:mock_uuid) { UUIDTools::UUID.random_create.to_s }
      let(:missing_resource_attributes) do
        {
          data: {
            id: mock_uuid,
            type: 'contacts',
            attributes: {
              name: 'foo_bar',
              updated_in_db_at: contact.updated_at
            }
          }
        }
      end

      it 'should return a not found status (404)' do
        put api_v2_contact_path(mock_uuid), missing_resource_attributes.to_json, headers
        expect(response.status).to eq(404), invalid_status_detail
      end
    end

    context 'that references a related resource that does not exist (404)' do
      let(:organization) { user.organization_accounts.first }
      let(:missing_related_resource_attributes) do
        {
          data: {
            type: 'organization_accounts',
            relationships: {
              data: {
                type: 'organizations',
                id: 'abc123'
              }
            }
          }
        }
      end

      it 'should return a not found status (404)' do
        put api_v2_user_organization_account_path(user.uuid), missing_related_resource_attributes.to_json, headers
        expect(response.status).to eq(404), invalid_status_detail
      end
    end

    context 'in which the resource object’s type does not match the server’s endpoint (409)' do
      let(:account_list) { user.account_lists.first }
      let(:task) { create(:task, account_list: account_list) }
      let(:constrained_attributes) do
        {
          data: {
            type: 'another_type',
            attributes: {
              subject: 'This is a task subject',
              updated_in_db_at: task.updated_at
            }
          }
        }
      end
      it 'should return a conflict status (409)' do
        put api_v2_task_path(task.uuid), constrained_attributes.to_json, headers
        expect(response.status).to eq(409), invalid_status_detail
      end
    end

    context 'in which the resource object’s id does not match the server’s endpoint (409)' do
      let(:mock_uuid) { UUIDTools::UUID.random_create }
      let(:account_list) { user.account_lists.first }
      let(:task) { create(:task, account_list: account_list) }
      let(:constrained_attributes) do
        {
          data: {
            id: mock_uuid,
            type: 'account_lists',
            attributes: {
              updated_in_db_at: task.updated_at
            }
          }
        }
      end
      it 'should return a conflict status (409)' do
        put api_v2_task_path(task.uuid), constrained_attributes.to_json, headers
        expect(response.status).to eq(409), invalid_status_detail
      end
    end
  end

  context 'in which the resource is expired (409)' do
    let(:account_list) { user.account_lists.first }
    let(:task) { create(:task, account_list: account_list) }
    let(:expired_attributes) do
      {
        data: {
          id: task.uuid,
          type: 'tasks',
          attributes: {
            updated_in_db_at: Time.parse('2016-01-26')
          }
        }
      }
    end
    it 'should return a conflict status (409)' do
      put api_v2_task_path(task.uuid), expired_attributes.to_json, headers
      expect(response.status).to eq(409), invalid_status_detail
    end
  end
end
