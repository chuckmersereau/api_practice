require 'spec_helper'

RSpec.describe 'Post Requests', type: :request do
  describe 'Creation with Client Generated UUID' do
    let(:headers) { { 'CONTENT_TYPE' => 'application/vnd.api+json' } }

    let(:user)         { create(:user_with_account) }
    let(:account_list) { user.account_lists.first }
    let(:desired_uuid) { SecureRandom.uuid }

    let(:contact_attributes) { attributes_for(:contact, name: 'Steve Rogers') }

    let(:json_data) { JSON.parse(response.body) }

    before { api_login(user) }

    context 'with the UUID in the correct placement: /data/id' do
      let(:post_attributes) do
        {
          data: {
            type: 'contacts',
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
            type: 'contacts',
            attributes: contact_attributes.merge!(
              id: desired_uuid,
              account_list_id: account_list.uuid
            )
          }
        }.to_json
      end

      it 'returns an error' do
        post api_v2_contacts_path, post_attributes, headers

        expect(response.status).to eq 403
        expect(json_data['errors'].first['title'])
          .to eq('A primary `id` cannot be sent at `/data/attributes/id`, it must be sent at `/data/id`')
      end
    end
  end
end
