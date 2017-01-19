RSpec.shared_examples 'bulk_update_examples' do
  include_context 'common_variables'

  describe '#update' do
    let(:unauthorized_resource) { create(factory_type) }
    let(:bulk_update_attributes) do
      { data: [{ id: resource.uuid, attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at) },
               { id: second_resource.uuid, attributes: incorrect_attributes },
               { id: unauthorized_resource.uuid, attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at) }] }
    end
    let(:parsed_body) { JSON.parse(response.body) }
    let(:successful_json_object_index) { parsed_body.find_index { |object| object['data'] } }
    let(:unsuccessful_json_object_index) { parsed_body.find_index { |object| object['data'].nil? } }
    let(:successful_json_object) { parsed_body[successful_json_object_index] }
    let(:unsuccessful_json_object) { parsed_body[unsuccessful_json_object_index] }

    before do
      api_login(user)
      put :update, bulk_update_attributes
    end

    it 'returns a 200 and the list of updated resources' do
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body).length).to eq(2)
    end

    it 'updates the resources which belong to user and do not have errors' do
      expect(successful_json_object['data']['id']).to eq(resource.uuid)
      expect(successful_json_object['data']['attributes'][reference_key.to_s]).to eq(reference_value)
      expect(resource.reload.send(reference_key)).to eq(reference_value)
    end

    it 'returns error objects for resources that were not updated, but belonged to user' do
      expect(unsuccessful_json_object['id']).to eq(second_resource.uuid)
      expect(unsuccessful_json_object['errors']).to be_present
      expect(resource.reload.send(reference_key)).to_not eq(incorrect_attributes[reference_value])
    end

    it 'does not update resources that do not belong to current user' do
      expect(unauthorized_resource.reload.send(reference_key)).to_not eq(correct_attributes[reference_value])
    end
  end
end
