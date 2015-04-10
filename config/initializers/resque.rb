resque_config = YAML.load(ERB.new(File.read(Rails.root.join('config', 'resque.yml'))).result)
Resque.redis = resque_config[Rails.env]
