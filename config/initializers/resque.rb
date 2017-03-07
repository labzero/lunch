if ENV['REDIS_URL'] && !ENV['RESQUE_REDIS_URL']
  ENV['RESQUE_REDIS_URL'] = RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'resque')
end
config_location = Pathname.new(ENV['RESQUE_CONFIG_FILE'] || Rails.root.join('config', 'resque.yml'))
environment = (defined?(Rails) && Rails.env) || ENV['RAILS_ENV'] || ENV['RACK_ENV']
resque_config = YAML.load(ERB.new(File.read(config_location)).result)
Resque.redis = resque_config[environment]
Resque.redis.namespace = RedisHelper.namespace_from_url(resque_config[environment])