require 'rails_helper'

RSpec.describe 'Error Response Format', type: :request do
  let!(:user) { create(:user_with_account) }

  let!(:headers) do
    {
      'ACCEPT' => 'application/vnd.api+json',
      'CONTENT_TYPE' => 'application/vnd.api+json'
    }
  end

  let(:parsed_response_body) { JSON.parse(response.body) }

  before do
    api_login(user)
  end

  context 'StandardError' do
    subject { get api_v2_contacts_path, nil, headers }

    before { allow(Contact).to receive(:where).and_raise(StandardError) }

    it 'has a response body that contains error objects in json api format' do
      subject
      expect(response.body).to eq '{"errors":[{"status":"500","title":"Internal Server Error"}]}'
    end
  end

  context 'ActiveRecord::RecordNotFound' do
    let(:uuid) { SecureRandom.uuid }
    let(:message) { "Couldn't find Contact with 'uuid'=#{uuid}" }

    let(:expected_error_data) do
      {
        errors: [
          {
            status: '404',
            title: 'Not Found',
            detail: message
          }
        ]
      }.deep_stringify_keys
    end

    subject { get api_v2_contact_path(id: uuid), nil, headers }

    it 'has a response body that contains error objects in json api format' do
      subject
      expect(JSON.parse(response.body)).to eq expected_error_data
    end
  end

  context 'ActionController::RoutingError' do
    describe 'with complete headers' do
      subject { get '/this_route_does_not_exist', nil, headers }
      it 'has a response body that contains error objects in json api format' do
        subject

        expect(response.body).to eq '{"errors":[{"status":"404","title":"Not Found","detail":"Route not found"}]}'
      end
    end

    describe 'without an ACCEPT header' do
      let(:headers) { { 'ACCEPT' => '', 'CONTENT_TYPE' => 'application/vnd.api+json' } }
      subject { get '/this_route_does_not_exist', nil, headers }

      it 'has a response body that contains error objects in json api format' do
        subject
        expect(response.body).to eq '{"errors":[{"status":"404","title":"Not Found","detail":"Route not found"}]}'
      end
    end
  end
end
