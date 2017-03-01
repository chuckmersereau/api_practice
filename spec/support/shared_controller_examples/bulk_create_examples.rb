RSpec.shared_examples 'bulk_create_examples' do
  include_context 'common_variables'

  describe '#create' do
    let(:first_uuid) { SecureRandom.uuid }
    let(:second_uuid) { SecureRandom.uuid }
    let(:third_uuid) { SecureRandom.uuid }

    let(:unauthorized_resource) { create(factory_type) }
    let(:bulk_create_attributes) do
      {
        data: [
          {
            data: {
              type: resource_type,
              id: first_uuid,
              attributes: correct_attributes
            }.merge!(relationships: relationships)
          },
          {
            data: {
              type: resource_type,
              id: second_uuid,
              attributes: incorrect_attributes
            }.merge!(relationships: relationships)
          },
          {
            data: {
              type: resource_type,
              id: third_uuid,
              attributes: correct_attributes
            }.merge!(relationships: relationships)
          }
        ]
      }
    end

    let(:response_body) { JSON.parse(response.body) }
    let(:response_errors) { response_body['errors'] }

    before do
      api_login(user)
    end

    it 'returns a 200 and the list of created resources' do
      post :create, bulk_create_attributes
      expect(response.status).to eq(200), invalid_status_detail
      expect(response_body.length).to eq(3)
    end

    it "returns a 400 if one of the data objects doesn't contain an id" do
      post :create, data: bulk_create_attributes[:data].append(data: { attributes: {} })
      expect(response.status).to eq(400), invalid_status_detail
    end

    it 'creates the resources which belong to users and do not have errors' do
      expect do
        post :create, bulk_create_attributes
      end.to change { resource.class.count }.by(2)
      expect(response_body.detect { |hash| hash.dig('data', 'id') == first_uuid }['errors']).to be_blank
      expect(response_body.detect { |hash| hash.dig('id') == second_uuid }['errors']).to be_present
      expect(response_body.detect { |hash| hash.dig('data', 'id') == third_uuid }['errors']).to be_blank
    end

    it 'returns error objects for resources that were not created, but belonged to user' do
      expect do
        put :create, bulk_create_attributes
      end.to_not change { second_resource.reload.send(reference_key) }
      response_with_errors = response_body.detect { |hash| hash.dig('id') == second_uuid }
      expect(response_with_errors['errors']).to be_present
      expect(response_with_errors['errors'].detect { |hash| hash.dig('source', 'pointer') == "/data/attributes/#{reference_key}" }).to be_present
    end

    context 'resources forbidden' do
      let!(:bulk_create_attributes_with_forbidden_resource) do
        {
          data: [
            {
              data: {
                type: resource_type,
                id: first_uuid,
                attributes: correct_attributes
              }
            },
            {
              data: {
                type: resource_type,
                id: second_uuid,
                attributes: correct_attributes,
                relationships: {
                  account_list: {
                    data: {
                      id: create(:account_list).uuid,
                      type: 'account_lists'
                    }
                  }
                }
              }
            },
            {
              data: {
                type: resource_type,
                id: third_uuid,
                attributes: correct_attributes
              }
            }
          ]
        }
      end

      it 'does not create resources for users that are not signed in' do
        api_logout
        expect do
          post :create
        end.not_to change { resource.class.count }
        expect(response.status).to eq(401), invalid_status_detail
      end

      it "returns a 403 when users tries to associate resource to an account list that doesn't belong to them" do
        expect do
          post :create, bulk_create_attributes_with_forbidden_resource
        end.not_to change { resource.class.count }
        expect(response.status).to eq(403), invalid_status_detail
      end
    end
  end
end
