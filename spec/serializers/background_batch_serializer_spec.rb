require 'rails_helper'

RSpec.describe BackgroundBatchSerializer, type: :serializer do
  let(:background_batch) { create(:background_batch) }
  subject { described_class.new(background_batch) }

  describe '#total' do
    it 'should return total number of requests' do
      # background_batch factory already creates request
      background_batch.requests.create(path: 'api/v2/user')
      background_batch.requests.create(path: 'api/v2/user')
      expect(subject.total).to eq 3
    end
  end

  describe '#pending' do
    it 'should return total number of pending requests' do
      # background_batch factory already creates request
      background_batch.requests.create(path: 'api/v2/user', status: 'complete')
      background_batch.requests.create(path: 'api/v2/user')
      expect(subject.pending).to eq 2
    end
  end
end
