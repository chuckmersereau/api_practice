require 'rails_helper'

RSpec.describe 'Server Responsibilites', type: :request do
  describe 'Headers' do
    let(:user) { create(:user_with_account) }

    context 'logged in users' do
      before { api_login(user) }

      context 'with no Content-Type' do
        let(:headers) { { 'CONTENT_TYPE' => '', 'ACCEPT' => '' } }
        it 'should return a unsupported media type status (415)' do
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 415
        end

        it 'should return "application/vnd.api+json" as the Content-Type' do
          get api_v2_contacts_path, nil, headers
          expect(response.content_type).to eq('application/vnd.api+json')
        end
      end

      context 'with a correct Content-Type' do
        it 'should return a success status (200)' do
          headers = { 'CONTENT_TYPE' => 'application/vnd.api+json', 'ACCEPT' => '' }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 200
        end
      end

      context 'with an incorrect Content-Type' do
        it 'should return an unsupported media type status (415)' do
          headers = { 'CONTENT_TYPE' => 'application/foobar', 'ACCEPT' => '' }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 415
        end
      end

      context 'with a jsonapi Accept header' do
        it 'should return a success status (200)' do
          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => 'application/vnd.api+json'
          }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 200
        end
      end

      context 'with a mixed jsonapi Accept header' do
        it 'should return a success status (200)' do
          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => 'application/vnd.api+json,application/vnd.api+json;charset=test'
          }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 200
        end
      end

      context 'with multiple modified jsonapi Accept header' do
        it 'should return a not acceptable status (406)' do
          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => 'application/vnd.api+json;charset=test,application/vnd.api+json;charset=test'
          }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 406
        end
      end

      context 'with a glob Accept header' do
        it 'should return a succes status (200)' do
          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => '*/*'
          }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 200
        end
      end

      context 'with a modified glob Accept header' do
        it 'should return a succes status (200)' do
          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => '*/*q=1.2'
          }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 200
        end
      end

      context 'with modified jsonapi Accept header' do
        it 'should return a not acceptable status (406)' do
          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => 'application/vnd.api+json;charset=test'
          }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 406
        end
      end

      context 'with an Accept header that is not jsonapi' do
        it 'should return a not acceptable status (406)' do
          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => 'text/plain'
          }
          get api_v2_contacts_path, nil, headers
          expect(response.status).to eq 406
        end
      end

      context 'with no Accept and/or CONTENT_TYPE header for controllers accepting it' do
        it 'should return a succes status (200)' do
          headers = {
            'CONTENT_TYPE' => 'multipart/form-data',
            'ACCEPT' => 'text/csv'
          }
          get api_v2_exports_path, nil, headers
          expect(response.status).to eq 200
        end
      end
    end

    context 'authorization' do
      context 'with a correct json web token' do
        it 'should return a succes status (200)' do
          json_web_token = JsonWebToken.encode(
            user_uuid: user.uuid,
            exp: 24.hours.from_now.utc.to_i
          )

          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => '*/*',
            'Authorization' => "Bearer #{json_web_token}"
          }

          get api_v2_exports_path, nil, headers
          expect(response.status).to eq 200
        end
      end

      context 'with an incorrect json web token' do
        it 'should return a succes status (200)' do
          json_web_token = JsonWebToken.encode(
            random_field: 123_456
          )

          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => '*/*',
            'Authorization' => "Bearer #{json_web_token}"
          }

          get api_v2_exports_path, nil, headers
          expect(response.status).to eq 401
        end
      end

      context 'with a json web token that is expired' do
        it 'should return a succes status (200)' do
          json_web_token = JsonWebToken.encode(
            user_uuid: user.uuid,
            exp: 10.minutes.ago.utc
          )

          headers = {
            'CONTENT_TYPE' => 'application/vnd.api+json',
            'ACCEPT' => '*/*',
            'Authorization' => "Bearer #{json_web_token}"
          }
          get api_v2_exports_path, nil, headers
          expect(response.status).to eq 401
        end
      end
    end
  end
end
