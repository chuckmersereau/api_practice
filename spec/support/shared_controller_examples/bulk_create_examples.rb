RSpec.shared_examples 'bulk_create_examples' do
  include_context 'common_variables'

  describe '#create' do
    let(:first_id) { SecureRandom.uuid }
    let(:second_id) { SecureRandom.uuid }
    let(:third_id) { SecureRandom.uuid }

    let(:unauthorized_resource) { create(factory_type) }
    let(:bulk_create_attributes) do
      {
        data: [
          {
            data: {
              type: resource_type,
              id: first_id,
              attributes: correct_attributes
            }.merge!(relationships: relationships)
          },
          {
            data: {
              type: resource_type,
              id: second_id,
              attributes: incorrect_attributes
            }.merge!(relationships: relationships)
          },
          {
            data: {
              type: resource_type,
              id: third_id,
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

    context 'resources forbidden' do
      let!(:bulk_create_attributes_with_forbidden_resource) do
        {
          data: [
            {
              data: {
                type: resource_type,
                id: first_id,
                attributes: correct_attributes
              }.merge(relationships: relationships)
            },
            {
              data: {
                type: resource_type,
                id: second_id,
                attributes: correct_attributes
              }.merge(relationships: found_forbidden_relationships)
            },
            {
              data: {
                type: resource_type,
                id: third_id,
                attributes: correct_attributes
              }.merge(relationships: relationships)
            }
          ]
        }
      end

      let!(:found_forbidden_relationships) do
        defined?(forbidden_relationships) ? forbidden_relationships : default_forbidden_relationships
      end

      let!(:default_forbidden_relationships) do
        {
          account_list: {
            data: {
              id: create(:account_list).id,
              type: 'account_lists'
            }
          }
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
