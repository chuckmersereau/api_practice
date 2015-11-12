# Based on: https://github.com/andys/sidekiq_memlimit
class SidekiqMemNotifier
  class << self
    attr_accessor :threshold_mb, :sleep_time, :max_mb_percent,
                  :last_time_emailed
    attr_reader :monitor_thread

    def start
      self.sleep_time ||= 5
      self.max_mb_percent = ENV['SIDEKIQ_WARN_PERCENT_MEM'].try(:to_f) || 0.95
      self.threshold_mb = ENV['CONTAINER_MB'].to_i * max_mb_percent
      self.threshold_mb = nil unless threshold_mb > 1
      start_monitor_thread if sidekiq_running?
    end

    def sidekiq_running?
      defined?(Sidekiq::CLI)
    end

    def start_monitor_thread
      if !@monitor_thread || !@monitor_thread.alive?
        @monitor_thread = Thread.new { check_memory_loop }
        @monitor_thread.priority = 1
      end
    end

    def check_memory_loop
      loop { check_memory_iteration }
    rescue
      Sidekiq.logger.error "#{self}: #{$ERROR_INFO.class} exception: #{$ERROR_INFO}"
    end

    def check_memory_iteration
      sleep sleep_time
      return unless threshold_mb && rss_mb > threshold_mb
      GC.start
      mb = rss_mb
      return unless threshold_mb && mb > threshold_mb
      memory_threshold_exceeded(mb)
    end

    def rss_mb
      NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
    end

    def memory_threshold_exceeded(mb)
      msgs = threshold_exceeded_msgs(mb)
      msgs.each { |msg| Sidekiq.logger.error(msg) }
      notify_by_email(msgs)
    end

    def threshold_exceeded_msgs(mb)
      [
        "#{self}: Exceeded memory threshold (#{mb} > #{threshold_mb} MB)",
        "ENV['DYNO']: #{ENV['DYNO']}",
        "All jobs: #{Sidekiq::Workers.new.to_a}"
      ]
    end

    def notify_by_email(msgs)
      return if last_time_emailed.present? && last_time_emailed > 2.hours.ago
      self.last_time_emailed = Time.current
      ActionMailer::Base.mail(from: 'support@mpdx.org',
                              to: ENV['SIDEKIQ_WARN_EMAILS'],
                              subject: 'Sidekiq memory threshold',
                              body: msgs.join("\n")).deliver_now
    end
  end
end
