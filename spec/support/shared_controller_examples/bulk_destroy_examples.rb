RSpec.shared_examples 'bulk_destroy_examples' do
  include_context 'common_variables'

  describe '#destroy' do
    let!(:bulk_destroy_attributes) do
      {
        data: [
          {
            data: {
              type: resource_type,
              id: resource.uuid
            }
          },
          {
            data: {
              type: resource_type,
              id: second_resource.uuid
            }
          }
        ]
      }
    end

    let(:response_body) { JSON.parse(response.body) }
    let(:response_errors) { response_body['errors'] }

    it 'destroys resources for users that are signed in' do
      expect(resource_not_destroyed_scope.count).to be > 2, 'please define resource, second_resource, and third_resource'
      expect(resource.class.exists?(resource.id)).to be_truthy
      expect(resource.class.exists?(second_resource.id)).to be_truthy
      expect(resource.class.exists?(third_resource.id)).to be_truthy

      api_login(user)
      expect do
        delete :destroy, bulk_destroy_attributes
      end.to change { resource_not_destroyed_scope.count }.by(-2)

      expect(resource.class.exists?(resource.id)).to be_falsey
      expect(resource.class.exists?(second_resource.id)).to be_falsey
      expect(resource.class.exists?(third_resource.id)).to be_truthy
    end

    it 'responds with the deleted resources' do
      api_login(user)
      expect do
        delete :destroy, bulk_destroy_attributes
      end.to change { resource_not_destroyed_scope.count }.by(-2)

      expect(response.status).to eq(200), invalid_status_detail
      expect(response_body.size).to eq(2)
      expect(response_body.collect { |hash| hash.dig('data', 'id') }).to match_array([resource.uuid, second_resource.uuid])
    end

    context 'resources forbidden' do
      it 'does not destroy the resources for users that do not own the resources' do
        api_login(create(:user))
        expect do
          delete :destroy, bulk_destroy_attributes
        end.not_to change { resource.class.count }
        expect(response.status).to eq(404), invalid_status_detail
        expect(response_errors.size).to eq(1)
      end

      it 'does not destroy resources for users that are not signed in' do
        expect do
          delete :destroy
        end.not_to change { resource.class.count }
        expect(response.status).to eq(401), invalid_status_detail
      end
    end

    context 'resources not found' do
      it 'responds correctly if all resources are not found' do
        api_login(user)
        expect do
          delete :destroy, data: [{ data: { type: resource_type, id: SecureRandom.uuid } }]
        end.not_to change { resource.class.count }
        expect(response.status).to eq(404), invalid_status_detail
        expect(response_body['errors']).to be_present
        expect(response_body['data']).to be_blank
      end

      it 'responds correctly if only some resources are not found' do
        api_login(user)
        bulk_destroy_attributes[:data] << { data: { type: resource_type, id: SecureRandom.uuid } }
        expect do
          delete :destroy, data: bulk_destroy_attributes[:data]
        end.to change { resource_not_destroyed_scope.count }.by(-2)
        expect(response.status).to eq(200), invalid_status_detail
        expect(response_body.size).to eq(2)
      end
    end

    context 'request mixes resources that do belong to and do not belong to the current user' do
      let!(:bulk_destroy_attributes) do
        {
          data: [
            { data: { id: resource.uuid, type: resource_type } },
            { data: { id: create(factory_type).uuid, type: resource_type } }
          ]
        }
      end

      it 'still destroys some resources' do
        api_login(user)
        expect do
          delete :destroy, bulk_destroy_attributes
        end.to change { resource.class.count }.by(-1)
        expect(response.status).to eq(200), invalid_status_detail
      end
    end
  end
end
