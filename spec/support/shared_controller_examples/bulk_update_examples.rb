RSpec.shared_examples 'bulk_update_examples' do
  include_context 'common_variables'

  describe '#update' do
    let(:unauthorized_resource) { create(factory_type) }
    let(:bulk_update_attributes) do
      { data: [
        { data: { id: resource.uuid,        attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at) } },
        { data: { id: second_resource.uuid, attributes: incorrect_attributes } },
        { data: { id: third_resource.uuid,  attributes: correct_attributes.merge(updated_in_db_at: third_resource.updated_at) } }
      ] }
    end
    let(:response_body) { JSON.parse(response.body) }
    let(:response_errors) { response_body['errors'] }

    before do
      api_login(user)
    end

    it 'returns a 200 and the list of updated resources' do
      put :update, bulk_update_attributes
      expect(response.status).to eq(200), invalid_status_detail
      expect(response_body.length).to eq(3)
    end

    it 'updates the resources which belong to user and do not have errors' do
      expect do
        expect do
          put :update, bulk_update_attributes
        end.to change { resource.reload.updated_at }.and change { third_resource.reload.updated_at }
      end.to_not change { second_resource.updated_at }
      expect(response_body.detect { |hash| hash.dig('data', 'id') == resource.uuid }['errors']).to be_blank
      expect(response_body.detect { |hash| hash.dig('id') == second_resource.uuid }['errors']).to be_present
      expect(response_body.detect { |hash| hash.dig('data', 'id') == third_resource.uuid }['errors']).to be_blank
    end

    it 'returns error objects for resources that were not updated, but belonged to user' do
      expect do
        put :update, bulk_update_attributes
      end.to_not change { second_resource.reload.send(reference_key) }
      response_with_errors = response_body.detect { |hash| hash.dig('id') == second_resource.uuid }
      expect(response_with_errors['errors']).to be_present
      expect(response_with_errors['errors'].detect { |hash| hash.dig('source', 'pointer') == "/data/attributes/#{reference_key}" }).to be_present
    end

    context 'resources forbidden' do
      it 'does not update resources that do not belong to current user' do
        put :update, data: [{ data: { id: unauthorized_resource.uuid, attributes: { reference_key => reference_value } } }]
        expect(unauthorized_resource.reload.send(reference_key)).to_not eq(reference_value)
        expect(response.status).to eq(404), invalid_status_detail
        expect(response_errors.size).to eq(1)
      end

      it 'does not update resources for users that are not signed in' do
        api_logout
        expect do
          put :update
        end.not_to change { resource.class.order(:updated_at).last.updated_at }
        expect(response.status).to eq(401), invalid_status_detail
      end
    end

    context 'resources not found' do
      it 'responds correctly if all resources are not found' do
        expect do
          put :update, data: [{ data: { id: SecureRandom.uuid } }]
        end.not_to change { resource.class.order(:updated_at).last.updated_at }
        expect(response.status).to eq(404), invalid_status_detail
        expect(response_body['errors']).to be_present
        expect(response_body['data']).to be_blank
      end

      it 'responds correctly if only some resources are not found' do
        bulk_update_attributes[:data] << { data: { id: SecureRandom.uuid } }
        expect do
          put :update, data: bulk_update_attributes[:data]
        end.to change { resource.class.order(:updated_at).last.updated_at }
        expect(response.status).to eq(200), invalid_status_detail
        expect(response_body.size).to eq(3)
      end
    end

    context 'request mixes resources that do belong to and do not belong to the current user' do
      let!(:bulk_update_attributes) do
        { data: [
          { data: { id: resource.uuid,              attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at) } },
          { data: { id: second_resource.uuid,       attributes: incorrect_attributes } },
          { data: { id: unauthorized_resource.uuid, attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at) } }
        ] }
      end

      it 'still updates some resources' do
        expect do
          put :update, bulk_update_attributes
        end.to change { resource.class.order(:updated_at).last.updated_at }
        expect(response.status).to eq(200), invalid_status_detail
      end
    end
  end
end
