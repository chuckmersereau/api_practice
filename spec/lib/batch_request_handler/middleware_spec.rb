require 'spec_helper'

describe BatchRequestHandler::Middleware do
  let(:app) { -> (_env) { [200, { 'Content-Type' => 'text/plain' }, ['Hello World']] } }
  subject { described_class.new(app) }

  describe '#call' do
    context 'with a request to the batch endpoint' do
      let(:batched_requests) do
        [
          {
            method: 'GET',
            path: '/api/v2/users'
          },
          {
            method: 'GET',
            path: '/api/v2/constants'
          },
          {
            method: 'POST',
            path: '/api/v2/contacts',
            body: '{}'
          }
        ]
      end

      let(:batch_request_json) { { requests: batched_requests } }
      let(:batch_request_body) { JSON.dump(batch_request_json) }
      let(:env) { Rack::MockRequest.env_for('/api/v2/batch', method: 'POST', input: batch_request_body) }

      it 'should call the app for each request in the batch' do
        expect(app).to receive(:call).exactly(batched_requests.size).times.and_call_original

        subject.call(env)
      end

      it 'should return a rack response' do
        response = subject.call(env)

        expect(response).to be_an(Array)
        expect(response.length).to eq(3)
      end

      it 'should serialize the batched responses to json' do
        response = subject.call(env)
        body     = response.last[0]
        json     = JSON.parse(body)

        expect(json).to be_an(Array)
        expect(json.length).to eq(batched_requests.length)
      end
    end

    context 'with a request for any other endpoint' do
      let(:env) { Rack::MockRequest.env_for('/api/v2/foo', method: 'GET') }

      it 'should fall through to the app' do
        expect(app).to receive(:call).once.with(env)

        subject.call(env)
      end
    end
  end
end
