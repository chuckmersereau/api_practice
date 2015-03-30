rails_root = ENV['RAILS_ROOT'] || Rails.root.to_s
rails_env = ENV['RAILS_ENV'] || 'development'

redis_config = YAML.load_file(rails_root + '/config/redis.yml')

Sidekiq.configure_client do |config|
  config.redis = { url: 'redis://' + redis_config[rails_env],
                   namespace: "MPDX:#{rails_env}:resque"}
end

if Sidekiq::Client.method_defined? :reliable_push!
  Sidekiq::Client.reliable_push!
end

Sidekiq.configure_server do |config|
  config.reliable_fetch!
  config.reliable_scheduler!
  config.redis = { url: 'redis://' + redis_config[rails_env],
                   namespace: "MPDX:#{rails_env}:resque"}
end

Sidekiq.default_worker_options = { backtrace: true }
