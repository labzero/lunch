if ENV['REDIS_URL'] && !ENV['RESQUE_REDIS_URL']
  ENV['RESQUE_REDIS_URL'] = RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'resque')
end
resque_config = YAML.load(ERB.new(File.read(Rails.root.join('config', 'resque.yml'))).result)
Resque.redis = resque_config[Rails.env]
Resque.redis.namespace = RedisHelper.namespace_from_url(resque_config[Rails.env])