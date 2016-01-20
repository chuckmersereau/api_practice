require 'sidekiq_job_args_logger'
require 'sidekiq_mem_notifier'
require Rails.root.join('config', 'initializers', 'redis').to_s

Sidekiq.configure_client do |config|
  config.redis = { url: Redis.current.client.id,
                   namespace: "MPDX:#{Rails.env}:resque"}
end

if Sidekiq::Client.method_defined? :reliable_push!
  Sidekiq::Client.reliable_push!
end

Sidekiq.configure_server do |config|
  config.reliable_fetch!
  config.reliable_scheduler!
  config.redis = { url: Redis.current.client.id,
                   namespace: "MPDX:#{Rails.env}:resque"}
  config.server_middleware do |chain|
    chain.add SidekiqJobArgsLogger
    chain.add SidekiqWhodunnit
  end
end

Sidekiq.default_worker_options = {
  backtrace: true, 
  # Uniqueness lock lasts for 22 days as at that time jobs stop getting retried
  # and move to the "Dead" list.
  unique_job_expiration: 22 * 24 * 60 * 60
}

SidekiqMemNotifier.start
