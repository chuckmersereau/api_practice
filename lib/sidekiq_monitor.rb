class SidekiqMonitor
  class << self
    def queue_latency_too_high?
      default_queue_latency = Sidekiq::Queue.new.latency
      warn_threshold = ENV.fetch('SIDEKIQ_WARN_DEFAULT_QUEUE_LATENCY').to_i
      default_queue_latency > warn_threshold
    end
  end
end
