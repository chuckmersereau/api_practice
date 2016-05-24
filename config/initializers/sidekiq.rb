require 'sidekiq_job_args_logger'
require 'sidekiq_mem_notifier'
require Rails.root.join('config', 'initializers', 'redis').to_s

Sidekiq.configure_client do |config|
  config.redis = { url: Redis.current.client.id,
                   namespace: "MPDX:#{Rails.env}:resque" }
end

if Sidekiq::Client.method_defined? :reliable_push!
  Sidekiq::Client.reliable_push!
end

Sidekiq.configure_server do |config|
  Sidekiq::Logging.logger.level = Logger::WARN

  Rails.logger = Sidekiq::Logging.logger

  config.reliable_fetch!
  config.reliable_scheduler!
  config.redis = { url: Redis.current.client.id,
                   namespace: "MPDX:#{Rails.env}:resque" }
  config.server_middleware do |chain|
    chain.add SidekiqWhodunnit
  end
end

Sidekiq.default_worker_options = {
  backtrace: true,
  # Set uniqueness lock expiration to 24 hours to balance preventing
  # duplicate jobs from running (if uniqueness time is too short) and donor
  # import / email jobs not getting queued because the locks don't
  # always get cleared properly (perhaps on new deploys/out of memory
  # errors).
  unique_job_expiration: 24.hours
}

SidekiqMemNotifier.start
