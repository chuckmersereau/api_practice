require 'spec_helper'

RSpec.describe ApplicationSerializer, type: :serializer do
  describe 'time output' do
    let(:timestamp)     { 20.minutes.ago }
    let(:email_address) { create(:email_address, created_at: timestamp) }

    it 'ensures that the timezone output is UTC ISO-8601' do
      serializer  = ApplicationSerializer.new(email_address)
      parsed_json = JSON.parse(serializer.to_json)

      expect(parsed_json['created_at']).to eq timestamp.utc.iso8601
    end
  end
end
