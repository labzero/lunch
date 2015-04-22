if ENV['REDIS_URL'] && !ENV['RESQUE_REDIS_URL']
  redis_uri = URI(ENV['REDIS_URL'])
  redis_uri.path = case redis_uri.path
  when '', '/'
    '/resque'
  when /^\/\d+(\/)?$/
    redis_uri.path + ('/' if $1.nil?).to_s + 'resque'
  else
    redis_uri.path + '-resque'
  end
  ENV['RESQUE_REDIS_URL'] = redis_uri.to_s
end
resque_config = YAML.load(ERB.new(File.read(Rails.root.join('config', 'resque.yml'))).result)
Resque.redis = resque_config[Rails.env]
