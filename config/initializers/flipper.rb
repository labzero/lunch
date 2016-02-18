require 'flipper/adapters/redis'
require 'flipper/middleware/memoizer'

ENV['FLIPPER_REDIS_URL'] ||= if ENV['REDIS_URL']
  RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'flipper')
else
  'redis://localhost:6379/flipper'
end

options = {url: ENV['FLIPPER_REDIS_URL']}
client = Redis::Namespace.new(RedisHelper.namespace_from_url(ENV['FLIPPER_REDIS_URL']), redis: Redis.new(options))
adapter = Flipper::Adapters::Redis.new(client)
Rails.application.flipper = Flipper.new(adapter)
