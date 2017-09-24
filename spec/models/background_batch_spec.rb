require 'rails_helper'

RSpec.describe BackgroundBatch, type: :model do
  subject { build :background_batch }

  describe '#create_batch' do
    it 'creates a sidekiq batch and stores the batch_id' do
      subject.save
      expect(subject.batch_id).to_not be_nil
      expect(subject.status).to be_a(Sidekiq::Batch::Status)
    end
  end

  describe '#create_workers' do
    it 'creates workers in batch' do
      requests_attributes = []
      # background_batch factory already creates request
      requests_attributes.push(path: 'api/v2/user')
      requests_attributes.push(path: 'api/v2/constants')
      subject.requests_attributes = requests_attributes
      expect(BackgroundBatch::RequestWorker).to receive(:perform_async).exactly(3).times
      subject.save
    end
  end
end
