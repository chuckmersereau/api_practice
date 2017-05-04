require 'spec_helper'

describe BatchRequestHandler::Instruments::RequestValidator do
  let(:params) { {} }
  subject { described_class.new(params) }

  describe '#around_perform_request' do
    context 'with a valid request' do
      let(:env) { Rack::MockRequest.env_for('/api/v2/users') }

      it 'yields the request environment' do
        expect { |block| subject.around_perform_request(env, &block) }
          .to yield_with_args(env)
      end
    end

    context 'with an invalid request method' do
      let(:env) { Rack::MockRequest.env_for('/api/v2/users', method: 'OPTIONS') }

      it 'does not yield the request environment' do
        expect { |block| subject.around_perform_request(env, &block) }
          .to_not yield_control
      end

      it 'returns an error response' do
        status, headers, body = subject.around_perform_request(env) {}
        json = JSON.parse(body.first)

        expect(status).to be(405)
        expect(headers).to include('Content-Type' => 'application/json')
        expect(json).to have_key('errors')
        expect(json['errors'].length).to eq(1)
        expect(json['errors'][0]).to include('status', 'message', 'meta')
        expect(json['errors'][0]['meta']).to include('path', 'method', 'body')
      end
    end

    context 'with a valid request that is rejected for being batched at the controller level' do
      let(:env) { Rack::MockRequest.env_for('/api/v2/users') }
      let(:error_message) { 'You cannot access this endpoint from within a batch request' }
      let(:block) do
        lambda do |_env|
          raise BatchRequestHandler::Instruments::RequestValidator::InvalidBatchRequestError,
                status: 403,
                message: error_message
        end
      end

      it 'yields the request environment' do
        expect { |block| subject.around_perform_request(env, &block) }
          .to yield_with_args(env)
      end

      it 'returns an error response' do
        status, headers, body = subject.around_perform_request(env, &block)
        json = JSON.parse(body.first)

        expect(status).to be(403)
        expect(headers).to include('Content-Type' => 'application/json')
        expect(json).to have_key('errors')
        expect(json['errors'].length).to eq(1)
        expect(json['errors'][0]).to include('status', 'message', 'meta')
        expect(json['errors'][0]['message']).to eq(error_message)
        expect(json['errors'][0]['meta']).to include('path', 'method', 'body')
      end
    end
  end
end
