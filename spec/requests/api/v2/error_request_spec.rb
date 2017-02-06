require 'spec_helper'

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
    subject { get api_v2_contact_path(id: user.uuid), nil, headers }

    it 'has a response body that contains error objects in json api format' do
      subject
      expect(response.body).to eq '{"errors":[{"status":"404","title":"Not Found","detail":"ActiveRecord::RecordNotFound"}]}'
    end
  end

  context 'ActionController::RoutingError' do
    subject { get '/this_route_does_not_exist', nil, headers }

    it 'has a response body that contains error objects in json api format' do
      subject
      expect(response.body).to eq '{"errors":[{"status":"404","title":"Not Found"}]}'
    end
  end
end
