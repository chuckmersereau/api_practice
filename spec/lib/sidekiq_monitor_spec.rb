require 'spec_helper'

describe SidekiqMonitor do
  context '.queue_latency_too_high' do
    before do
      ENV['SIDEKIQ_WARN_DEFAULT_QUEUE_LATENCY'] = '600'
    end

    it 'returns true if default queue latency above threshold' do
      stub_latency(599.5)
      expect(SidekiqMonitor.queue_latency_too_high?).to be false
    end

    it 'returns false if default queue latency below threshold' do
      stub_latency(601.1)
      expect(SidekiqMonitor.queue_latency_too_high?).to be true
    end

    def stub_latency(latency)
      default_queue = double
      expect(Sidekiq::Queue).to receive(:new) { default_queue }
      expect(default_queue).to receive(:latency) { latency }
    end
  end
end
