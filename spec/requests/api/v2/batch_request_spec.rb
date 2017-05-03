require 'rails_helper'

RSpec.describe 'Batch Requests', type: :request do
  before { api_login(user) }
  let(:batch_endpoint) { '/api/v2/batch' }
  let(:headers) { { 'CONTENT_TYPE' => 'application/vnd.api+json', 'ACCEPT' => '' } }
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:get_current_user) { { method: 'GET', path: api_v2_user_path } }
  let(:get_constants) { { method: 'GET', path: api_v2_constants_path } }

  let(:contact_post_data) do
    {
      data: {
        type: :contacts,
        id: SecureRandom.uuid,
        attributes: attributes_for(:contact, name: 'Buster Bluth'),
        relationships: {
          account_list: {
            data: {
              type: 'account_lists',
              id: account_list.uuid
            }
          }
        }
      }
    }.to_json
  end

  let(:create_contact) { { method: 'POST', path: api_v2_contacts_path, body: contact_post_data } }

  let(:failing_contact_post_data) do
    {
      data: {
        type: :contacts,
        id: SecureRandom.uuid,
        attributes: attributes_for(:contact, name: 'Buster Bluth'),
        relationships: {
          account_list: {
            data: {
              type: 'account_lists',
              id: create(:account_list).uuid
            }
          }
        }
      }
    }.to_json
  end

  let(:failing_create_contact) { { method: 'POST', path: api_v2_contacts_path, body: failing_contact_post_data } }

  context 'with all passing requests' do
    let(:requests) { [get_current_user, get_constants, create_contact] }
    let(:batch_request) { { requests: requests }.to_json }

    it 'returns 200 ok' do
      post batch_endpoint, batch_request, headers

      expect(response.status).to eq(200), invalid_status_detail
    end

    it 'returns a json array with all the responses' do
      post batch_endpoint, batch_request, headers

      expect(json_response).to be_an(Array)
      expect(json_response.length).to eq(requests.length)
      expect(json_response[0]).to include('status', 'headers', 'body')
    end
  end

  context 'with a failing request' do
    let(:requests) { [get_current_user, failing_create_contact, get_constants] }
    let(:batch_request) { { requests: requests }.to_json }

    it 'returns a 200 ok' do
      post batch_endpoint, batch_request, headers

      expect(response.status).to eq(200), invalid_status_detail
    end

    it 'returns all the responses' do
      post batch_endpoint, batch_request, headers

      expect(json_response.length).to eq(requests.length)
    end
  end

  context 'with a failing request, with on_error set to ABORT' do
    let(:requests) { [get_current_user, failing_create_contact, get_constants] }
    let(:batch_request) { { requests: requests, on_error: 'ABORT' }.to_json }

    it 'returns an error status of whatever the failing request failed with' do
      post batch_endpoint, batch_request, headers

      expect(response.status).to_not eq(200), invalid_status_detail
      expect(response.status).to eq(json_response.last['status'].to_i)
    end

    it 'returns the responses up to and including the failed request, but no more' do
      post batch_endpoint, batch_request, headers

      expect(json_response.length).to eq(2)
    end
  end

  context 'with over 100 requests' do
    let(:requests) { [get_current_user] * 101 }
    let(:batch_request) { { requests: requests }.to_json }

    it 'returns a rate limit error' do
      post batch_endpoint, batch_request, headers

      expect(response.status).to eq(429), invalid_status_detail
    end
  end

  context 'with a malformed request inside the batch request' do
    let(:bad_request) { { method: 'OPTIONS', path: '/api/v2/user' } }
    let(:batch_request) { { requests: [get_current_user, bad_request] }.to_json }

    it 'returns a 200 ok' do
      post batch_endpoint, batch_request, headers

      expect(response.status).to eq(200), invalid_status_detail
    end

    it 'returns an error for that specific request' do
      post batch_endpoint, batch_request, headers

      expect(json_response[1]['status']).to eq(405), invalid_status_detail
    end
  end

  context 'with a request to a bulk endpoint inside the batch request' do
    let(:bulk_request) { { method: 'POST', path: '/api/v2/contacts/bulk' } }
    let(:batch_request) { { requests: [get_current_user, bulk_request] }.to_json }

    it 'returns a 200 ok' do
      post batch_endpoint, batch_request, headers

      expect(response.status).to eq(200), invalid_status_detail
    end

    it 'returns an error for that specific request' do
      post batch_endpoint, batch_request, headers

      expect(json_response[1]['status']).to eq(403), invalid_status_detail
    end
  end

  context 'with a malformed batch request' do
    it 'returns an error explaining how to use the batch endpoint' do
      post batch_endpoint, '', headers

      expect(response.status).to eq(400), invalid_status_detail
      expect(json_response).to include('errors')
    end
  end
end
