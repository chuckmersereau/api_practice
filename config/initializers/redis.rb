require 'redis'
require 'redis/objects'
require 'redis/namespace'
rails_root = ENV['RAILS_ROOT'] || Rails.root.to_s
rails_env = ENV['RAILS_ENV'] || 'development'

redis_config = YAML.load(ERB.new(File.read(Rails.root.join('config', 'redis.yml').to_s)).result)
host, port = redis_config[rails_env].split(':')
Redis.current = Redis::Namespace.new("MPDX:#{rails_env}", redis: Redis.new(host: host, port: port))
Mpdx::Application.configure do
  config.peek.adapter = :redis, {
    :client => Redis.current,
    :expires_in => 60 * 30 # => 30 minutes in seconds
  }
end
