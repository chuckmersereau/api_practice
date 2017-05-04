require 'spec_helper'

describe BatchRequestHandler::Instruments::RequestLimiter do
  let(:params) { {} } # see documentation on Instrument initialize arguments
  subject { described_class.new(params) }

  let(:not_too_many_requests) do
    1.upto(100).map do |num|
      {
        method: 'GET',
        path: "/url/for/request/#{num}"
      }
    end
  end

  let(:too_many_requests) do
    1.upto(101).map do |num|
      {
        method: 'GET',
        path: "/url/for/request/#{num}"
      }
    end
  end

  describe '#around_perform_requests' do
    context 'with 100 or less requests' do
      it 'accepts the batch request of requests' do
        expect do |block|
          subject.around_perform_requests(not_too_many_requests, &block)
        end.to yield_with_args(not_too_many_requests)
      end
    end

    context 'with more than 100 requests' do
      it 'rejects the batch request of requests' do
        expect do |block|
          subject.around_perform_requests(too_many_requests, &block)
        end.not_to yield_control
      end
    end
  end

  describe '#around_build_response' do
    let(:json_responses) { double('json_responses') }

    context 'when the request had not too many requests' do
      it 'yields the json_responses' do
        expect do |block|
          subject.around_build_response(json_responses, &block)
        end.to yield_with_args(json_responses)
      end
    end

    context 'when the request had too many requests' do
      before do
        subject.around_perform_requests(too_many_requests) { |requests| requests }
      end

      it 'does not yield the json_responses' do
        expect do |block|
          subject.around_build_response(json_responses, &block)
        end.not_to yield_control
      end

      it 'returns an error' do
        response = subject.around_build_response(json_responses) do |responses|
          responses
        end

        status, headers, body = response

        expect(status).to eq 429
        expect(headers).to eq('Content-Type' => 'application/json')
        expect(body).to eq(
          [
            {
              errors: [
                {
                  status: 429,
                  title:  'Too Many Requests',
                  detail: 'You only able to send up to 100 requests in a batch request'
                }
              ]
            }.to_json
          ]
        )
      end
    end
  end
end
