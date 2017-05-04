require 'spec_helper'

describe BatchRequestHandler::Instruments::Logging do
  let(:params) { {} }
  subject { described_class.new(params) }

  describe '#around_perform_request' do
    let(:env) { Rack::MockRequest.env_for('/api/v2/users') }
    let(:block) { -> (_env) {} }

    it 'logs to the logger' do
      expect(Rails.logger).to receive(:info)

      subject.around_perform_request(env, &block)
    end
  end
end
