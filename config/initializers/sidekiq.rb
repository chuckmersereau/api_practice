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
end

Sidekiq.default_worker_options = { backtrace: true, unique_job_expiration: 12 * 60 * 60}
