require 'rails_helper'

RSpec.describe BackgroundBatch::RequestWorker do
  let(:user) { create :user }
  let(:background_batch_request) { create :background_batch_request }
  subject { described_class.new }
  before do
    stub_request(:get, 'https://api.mpdx.org/api/v2/user')
      .to_return(status: 200,
                 body: "{\"id\":\"#{user.id}\"}",
                 headers: { accept: 'application/json' })
  end

  describe '#perform' do
    it 'should find background_batch_request' do
      expect(BackgroundBatch::Request).to(
        receive(:find).with(background_batch_request.id).and_return(background_batch_request)
      )
      subject.perform(background_batch_request.id)
    end
  end

  describe '#load_response' do
    before do
      allow(BackgroundBatch::Request).to(
        receive(:find_by!).with(id: background_batch_request.id).and_return(background_batch_request)
      )
    end
    it 'should call RestClient::Request.execute' do
      expect(RestClient::Request).to(
        receive(:execute).with(
          method: background_batch_request.request_method,
          payload: background_batch_request.request_body,
          url: background_batch_request.formatted_path,
          headers: background_batch_request.formatted_request_headers,
          timeout: nil
        ).and_call_original
      )
      subject.perform(background_batch_request.id)
    end

    it 'should call update_request' do
      allow(RestClient::Request).to(
        receive(:execute).with(
          method: background_batch_request.request_method,
          payload: background_batch_request.request_body,
          url: background_batch_request.formatted_path,
          headers: background_batch_request.formatted_request_headers,
          timeout: nil
        ).and_call_original
      )
      expect(subject).to receive(:update_request).and_call_original
      subject.perform(background_batch_request.id)
    end
  end

  describe '#request_params' do
    it 'should return request_params for RestClient::Request.execute' do
      subject.perform(background_batch_request.id)
      expect(subject.send(:request_params)).to eq(
        method: background_batch_request.request_method,
        payload: background_batch_request.request_body,
        url: background_batch_request.formatted_path,
        headers: background_batch_request.formatted_request_headers,
        timeout: nil
      )
    end
  end

  describe '#update_request' do
    it 'should call background_batch_request.update' do
      allow(BackgroundBatch::Request).to(
        receive(:find).with(background_batch_request.id).and_return(background_batch_request)
      )
      expect(background_batch_request).to receive(:update).with(
        response_body: "{\"id\":\"#{user.id}\"}",
        response_headers: { accept: 'application/json' },
        response_status: 200,
        status: 'complete'
      ).and_call_original
      subject.perform(background_batch_request.id)
    end
  end
end
