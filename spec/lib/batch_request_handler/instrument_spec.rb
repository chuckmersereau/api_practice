require 'spec_helper'

describe BatchRequestHandler::Instrument do
  let(:params) { {} }
  subject { described_class.new(params) }

  describe '.enabled_for?' do
    it 'matches anything' do
      batch_request = double('batch_request')
      expect(described_class.enabled_for?(batch_request)).to be(true)
    end
  end

  describe '#initialize' do
    it 'accepts one argument' do
      expect(described_class).to respond_to(:new).with(1).argument
    end
  end

  describe '#around_perform_requests' do
    let(:requests) { double('requests') }

    it 'accepts one argument' do
      expect(subject).to respond_to(:around_perform_requests).with(1).argument
    end

    it 'yields the provided argument' do
      expect { |b| subject.around_perform_requests(requests, &b) }
        .to yield_with_args(requests)
    end

    it 'returns the result of yield' do
      responses = double('responses')
      block     = -> (_requests) { responses }

      expect(subject.around_perform_requests(requests, &block)).to be(responses)
    end
  end

  describe '#around_perform_request' do
    let(:env) { double('env') }

    it 'accepts one argument' do
      expect(subject).to respond_to(:around_perform_request).with(1).argument
    end

    it 'yields the provided argument' do
      expect { |b| subject.around_perform_request(env, &b) }
        .to yield_with_args(env)
    end

    it 'returns the result of yield' do
      response = double('response')
      block    = -> (_env) { response }

      expect(subject.around_perform_request(env, &block)).to be(response)
    end
  end

  describe '#around_build_response' do
    let(:json_responses) { double('json_responses') }

    it 'accepts one argument' do
      expect(subject).to respond_to(:around_build_response).with(1).argument
    end

    it 'yields the provided argument' do
      expect { |b| subject.around_perform_request(json_responses, &b) }
        .to yield_with_args(json_responses)
    end

    it 'returns the result of yield' do
      batch_response = double('batch_response')
      block          = -> (_env) { batch_response }

      expect(subject.around_perform_request(json_responses, &block))
        .to be(batch_response)
    end
  end
end
