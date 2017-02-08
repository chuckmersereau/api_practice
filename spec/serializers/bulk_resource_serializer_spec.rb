require 'rails_helper'

RSpec.describe BulkResourceSerializer, type: :serializer do
  describe 'json output' do
    let(:contact_with_error) do
      contact = create(:contact)
      contact.errors.add(:name, 'Cannot be blank')
      contact
    end

    let(:contact) { create(:contact) }
    let(:resources) { [contact, create(:contact), contact_with_error] }

    let(:serializer) { BulkResourceSerializer.new(resources: resources) }
    let(:parsed_json_response) { JSON.parse(serializer.to_json) }

    it 'outputs the successes and failures in the correct format' do
      expect(parsed_json_response.length).to eq(3)
      expect(parsed_json_response.first['data']['id']).to eq(contact.uuid)
      expect(parsed_json_response.first['data']['attributes']['name']).to eq(contact.name)
      expect(parsed_json_response.last['id']).to eq(contact_with_error.uuid)
      expect(parsed_json_response.last['errors'].first['title']).to eq('Cannot be blank')
    end
  end
end
