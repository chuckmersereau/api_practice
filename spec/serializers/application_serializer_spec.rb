require 'spec_helper'

RSpec.describe ApplicationSerializer, type: :serializer do
  describe 'time output' do
    let(:timestamp)     { 20.minutes.ago }
    let(:email_address) { create(:email_address, created_at: timestamp) }
    let(:serializer) { ApplicationSerializer.new(email_address) }
    let(:parsed_json) { JSON.parse(serializer.to_json) }

    it 'ensures that the timezone output is UTC ISO-8601' do
      expect(parsed_json['created_at']).to eq timestamp.utc.iso8601
    end

    it 'includes the updated_in_db_at fied' do
      expect(parsed_json['updated_in_db_at']).to eq(email_address.updated_at.to_s)
    end
  end
end
