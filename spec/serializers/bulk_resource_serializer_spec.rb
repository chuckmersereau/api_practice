require 'rails_helper'

RSpec.describe BulkResourceSerializer, type: :serializer do
  describe 'json output' do
    let(:contact_with_error) do
      contact = build(:contact)
      contact.errors.add(:name, 'Cannot be blank')
      contact
    end

    let(:contact_with_conflict_error) do
      contact = build(:contact)
      contact.errors.add(:updated_in_db_at, 'is not equal to the current value in the database')
      contact
    end

    let(:contact) { build(:contact, id: SecureRandom.uuid) }
    let(:resources) { [contact, create(:contact), contact_with_error, contact_with_conflict_error] }

    let(:serializer) { BulkResourceSerializer.new(resources: resources) }
    let(:parsed_json_response) { JSON.parse(serializer.to_json) }

    it 'outputs the successes and failures in the correct format' do
      expect(parsed_json_response.length).to eq(4)
      expect(parsed_json_response.first['data']['id']).to eq(contact.id)
      expect(parsed_json_response.first['data']['attributes']['name']).to eq(contact.name)
      expect(parsed_json_response.third['id']).to eq(contact_with_error.id)
      expect(parsed_json_response.third['errors'].first['title']).to eq('Cannot be blank')
      expect(parsed_json_response.last['errors'].first['status']).to eq(409)
    end
  end
end
