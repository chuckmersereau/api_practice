require 'spec_helper'
require 'support/batch_request_helpers'

describe BatchRequestHandler::Instruments::AbortOnError do
  let(:successful_request) { double('success') }
  let(:successful_response) { Rack::Response.new([], 200).finish }
  let(:successful_json_response) { { status: 200 } }
  let(:failing_request) { double('fail') }
  let(:failing_response) { Rack::Response.new([], 400).finish }
  let(:failing_json_response) { { status: 400 } }

  let(:app) do
    lambda do |env|
      case env
      when successful_request then successful_response
      when failing_request then failing_response
      end
    end
  end

  let(:around_perform_requests_block) do
    lambda do |request_envs|
      request_envs.map { |env| subject.around_perform_request(env, &app) }
    end
  end

  it 'should only be enabled when on_error is set to ABORT' do
    batch_request = create_empty_batch_request_with_params(on_error: 'ABORT')

    expect(described_class).to be_enabled_for(batch_request)
  end

  let(:params) { {} }
  subject { described_class.new(params) }

  describe '#around_perform_requests' do
    let(:block) { around_perform_requests_block }

    context 'with all successful requests' do
      let(:requests) { [successful_request, successful_request] }

      it 'returns both requests' do
        responses = subject.around_perform_requests(requests, &block)

        expect(responses).to eq([successful_response, successful_response])
      end
    end

    context 'with a failing request' do
      let(:requests) { [successful_request, failing_request, successful_request] }

      it 'returns only the requests up to and including the failing request' do
        responses = subject.around_perform_requests(requests, &block)

        expect(responses).to eq([successful_response, failing_response])
      end
    end
  end

  describe 'around_perform_request' do
    context 'with a successful request' do
      it 'should not throw :error' do
        expect { subject.around_perform_request(successful_request, &app) }
          .to_not throw_symbol(:error)
      end
    end

    context 'with a failing request' do
      it 'should throw :error' do
        expect { subject.around_perform_request(failing_request, &app) }
          .to throw_symbol(:error)
      end
    end
  end

  describe 'around_build_response' do
    let(:block) do
      -> (_json_responses) { [200, { 'Content-Type' => 'application/json' }, ['']] }
    end

    context 'when the batch request did not abort' do
      let(:json_responses) { [successful_json_response] }

      before do
        subject.around_perform_requests([successful_request], &around_perform_requests_block)
      end

      it 'should return a rack response with a 200 status' do
        status, = subject.around_build_response(json_responses, &block)

        expect(status).to eq(200)
      end
    end

    context 'when the batch request did abort' do
      let(:json_responses) { [successful_json_response, failing_json_response] }

      before do
        subject.around_perform_requests([successful_request, failing_request], &around_perform_requests_block)
      end

      it 'should return a rack response with a status equal to the last response\'s status' do
        status, = subject.around_build_response(json_responses, &block)

        expect(status).to eq(json_responses.last[:status])
      end
    end
  end
end
