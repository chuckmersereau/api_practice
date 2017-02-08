require 'rails_helper'

RSpec.describe ServiceSerializer, type: :serializer do
  let(:account_list) { create(:account_list) }
  let(:service_resource) { Reports::YearDonations.new(account_list: account_list) }
  subject { JSON.parse(ServiceSerializer.new(service_resource).to_json) }

  it 'id is nil' do
    expect(subject['id']).to be_nil
  end

  it 'created_at is current time' do
    time = Time.current
    travel_to time do
      expect(subject['created_at']).to eq(time.utc.iso8601)
    end
  end

  it 'updated_at is nil' do
    expect(subject['updated_at']).to be_nil
  end

  it 'updated_in_db_at is nil' do
    expect(subject['updated_in_db_at']).to be_nil
  end
end
