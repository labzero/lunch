ENV['OBJECT_REDIS_URL'] ||= if ENV['REDIS_URL']
  RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'objects')
else
  'redis://localhost:6379/objects'
end

Redis::Objects.redis = Redis::Namespace.new(RedisHelper.namespace_from_url(ENV['OBJECT_REDIS_URL']), :redis => Redis.new(url: ENV['OBJECT_REDIS_URL']))
