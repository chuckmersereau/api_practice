require 'spec_helper'
require 'json_web_token'
require 'json_web_token/middleware'

describe JsonWebToken::Middleware do
  let(:app) { MockRackApp.new }
  let(:decode_callback) { -> (env) { env } }
  subject { described_class.new(app, &decode_callback) }

  it 'is a middleware' do
    expect(subject).to respond_to(:call).with(1).argument
  end

  context 'during a request to a non api/v2 endpoint' do
    before { make_request }
    let(:request_env) { Rack::MockRequest.env_for('/api/v1/users') }

    it 'does not modify the environment' do
      expect(app.env).to eq(request_env)
    end
  end

  context 'during a request to an api/v2 endpoint' do
    # before { make_request }
    let(:request_env) { Rack::MockRequest.env_for('/api/v2/users') }

    context 'when there is no Authorization header present' do
      it 'does not modify the environment' do
        make_request
        expect(app.env).to eq(request_env)
      end

      it 'does not fire the callback' do
        expect(decode_callback).to_not receive(:call)
        make_request
      end
    end

    context 'when there is an Authorization header present' do
      context 'and it contains an invalid JWT token' do
        let(:request_env) { Rack::MockRequest.env_for('/api/v2/users', 'HTTP_AUTHORIZATION' => 'Bearer asdf') }

        it 'does not modify the environment' do
          make_request
          expect(app.env).to eq(request_env)
        end

        it 'does not fire the callback' do
          expect(decode_callback).to_not receive(:call)
          make_request
        end
      end

      context 'and it contains a valid JWT token' do
        let(:jwt_payload) { { user_id: 'abc-123' } }
        let(:jwt_token) { JsonWebToken.encode(jwt_payload) }
        let(:request_env) { Rack::MockRequest.env_for('/api/v2/users', 'HTTP_AUTHORIZATION' => "Bearer #{jwt_token}") }

        it 'adds the decoded jwt_token to the request env' do
          make_request

          expect(app.env).to have_key('auth.jwt_payload')
          expect(app.env['auth.jwt_payload']).to match(jwt_payload)
        end

        it 'fires the callback' do
          expect(decode_callback).to receive(:call).and_call_original
          make_request
        end
      end
    end
  end

  def make_request
    subject.call(request_env)
  end
end

class MockRackApp
  attr_reader :env

  def call(env)
    @env = env
    [200, { 'Content-Type' => 'text/plain' }, ['OK']]
  end
end
