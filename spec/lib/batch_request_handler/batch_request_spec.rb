require 'spec_helper'

describe BatchRequestHandler::BatchRequest do
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
  subject { BatchRequestHandler::BatchRequest.new(env) }

  describe '#add_instrumentation' do
    let(:instrument_class) { double('instrument') }

    context 'with a matching instrument class' do
      before do
        allow(instrument_class).to receive(:enabled_for?).with(subject).and_return(true)
      end

      it 'should add an instance of the class' do
        expect(instrument_class).to receive(:new).with(subject.params)

        subject.add_instrumentation(instrument_class)
      end
    end

    context 'with a non matching instrument class' do
      before do
        allow(instrument_class).to receive(:enabled_for?).with(subject).and_return(false)
      end

      it 'should add an instance of the class' do
        expect(instrument_class).to_not receive(:new)

        subject.add_instrumentation(instrument_class)
      end
    end
  end

  describe '#process' do
    let(:app) { -> (_env) { [200, { 'Content-Type' => 'text/plain' }, ['Hello World']] } }

    context 'with two instrumentations' do
      let(:instrument_one_class) { Class.new(BatchRequestHandler::Instrument) }
      let(:instrument_one_instance) { instrument_one_class.new({}) }
      let(:instrument_two_class) { Class.new(BatchRequestHandler::Instrument) }
      let(:instrument_two_instance) { instrument_two_class.new({}) }

      before do
        allow(instrument_one_class).to receive(:new).and_return(instrument_one_instance)
        allow(instrument_two_class).to receive(:new).and_return(instrument_two_instance)
        subject.add_instrumentation(instrument_one_class)
        subject.add_instrumentation(instrument_two_class)
      end

      it 'should call all the instrumented hooks in order' do
        expect(instrument_one_instance).to receive(:around_perform_requests).and_call_original.ordered
        expect(instrument_two_instance).to receive(:around_perform_requests).and_call_original.ordered
        batched_requests.length.times do
          expect(instrument_one_instance).to receive(:around_perform_request).and_call_original.ordered
          expect(instrument_two_instance).to receive(:around_perform_request).and_call_original.ordered
          expect(app).to receive(:call).and_call_original.ordered
        end
        expect(instrument_one_instance).to receive(:around_build_response).and_call_original.ordered
        expect(instrument_two_instance).to receive(:around_build_response).and_call_original.ordered

        subject.process(app)
      end
    end
  end
end
