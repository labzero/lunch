ENV['CACHE_REDIS_URL'] ||= if ENV['REDIS_URL']
  RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'cache')
else
  'redis://localhost:6379/cache'
end

cache_store_args = {
  namespace: RedisHelper.namespace_from_url(ENV['CACHE_REDIS_URL']),
  expires_in: 1.day
}
Rails.application.config.cache_store = :redis_store, ENV['CACHE_REDIS_URL'], cache_store_args