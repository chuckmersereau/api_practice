require 'redis'
require 'redis/objects'
require 'redis/namespace'

redis_config = YAML.load(ERB.new(File.read(Rails.root.join('config', 'redis.yml'))).result)
host, port = redis_config[Rails.env].split(':')
Redis.current = Redis::Namespace.new("MPDX:#{Rails.env}", redis: Redis.new(host: host, port: port))
