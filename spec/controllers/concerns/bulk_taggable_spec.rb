require 'rails_helper'

class BulkTaggableTestController < Api::V2Controller
  include BulkTaggable
  resource_type :tags
  skip_before_action :validate_and_transform_json_api_params
  skip_after_action :verify_authorized
end

describe Api::V2Controller do
  let!(:user)    { create(:user_with_account) }
  let!(:contact) { create(:contact) }
  let(:data_param) do
    { data: { attributes: { name: name_param }, type: 'tags' } }
  end

  describe '#tag_names' do
    controller BulkTaggableTestController do
      def show
        Contact.first.tag_list.add(*tag_names)
      end
    end

    before do
      routes.draw { get 'show' => 'bulk_taggable_test#show' }
      api_login(user)
    end

    context 'valid tag name field' do
      let(:name_param) { 'valid tag' }

      it 'will not raise an error' do
        expect { get :show, data: [data_param] }.not_to raise_error
      end

      it 'returns a status of HTTP 200: OK' do
        get :show, data: [data_param]
        expect(response.status).to eq(200)
      end
    end

    context 'the provided tag name was not a string' do
      let(:name_param) do
        { id: '12345678-b508-11e7-be77-9dcc9b77300c', name: 'not a string' }
      end

      it 'will not raise an error' do
        expect { get :show, data: [data_param] }.not_to raise_error
      end

      it 'returns a status of HTTP 400: Bad Request' do
        get :show, data: [data_param]
        expect(response.status).to eq(400)
      end

      it 'returns a helpful error message' do
        get :show, data: [data_param]
        expect(response_json['errors'][0]['detail']).to include \
          'Expected tag name to be a string, but it was an object'
      end
    end
  end
end
