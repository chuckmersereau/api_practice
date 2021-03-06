require 'sidekiq_job_args_logger'
require 'sidekiq_mem_notifier'
require 'datadog/statsd'
require Rails.root.join('config', 'initializers', 'redis').to_s

Sidekiq.configure_client do |config|
  config.redis = { url: Redis.current.client.id,
                   namespace: "MPDX:#{Rails.env}:resque" }
end

if Sidekiq::Client.method_defined? :reliable_push!
  Sidekiq::Client.reliable_push!
end

Sidekiq.configure_server do |config|
  Sidekiq::Logging.logger.level = Logger::WARN unless Rails.env.development?

  Rails.logger = Sidekiq::Logging.logger

  config.super_fetch!
  config.reliable_scheduler!
  config.redis = { url: Redis.current.client.id,
                   namespace: "MPDX:#{Rails.env}:resque" }
  config.server_middleware do |chain|
    chain.add SidekiqAuditedUser
  end

  config.error_handlers << Proc.new { |exception, context_hash| Rollbar.error(exception, context_hash) }
end

Sidekiq.default_worker_options = {
  backtrace: false,
  # Set uniqueness lock expiration to 24 hours to balance preventing
  # duplicate jobs from running (if uniqueness time is too short) and donor
  # import / email jobs not getting queued because the locks don't
  # always get cleared properly (perhaps on new deploys/out of memory
  # errors).
  unique_expiration: 24.hours
}

unless Rails.env.development? || Rails.env.test?
  Sidekiq::Pro.dogstatsd = -> { Datadog::Statsd.new(ENV['DATADOG_HOST'], ENV['DATADOG_PORT']) }
end

Sidekiq::Extensions.enable_delay!

SidekiqMemNotifier.start
