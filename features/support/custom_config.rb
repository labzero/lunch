module CustomConfig
  unless defined? @@env_config
    puts 'loading environments.yml...'
    env = (ENV['ENVIRONMENT'] && ENV['ENVIRONMENT'].to_sym) || :dev
    environments = YAML.load(ERB.new(File.read(File.expand_path('../../../config/environments.yml', __FILE__))).result)
    puts environments.inspect
    @@env_config = environments[env.to_s]
    raise "No config found for environment: #{env}" unless @@env_config
  end

  unless defined? @@me
    puts 'loading me.yml...'
    @@me = YAML.load(ERB.new(File.read(File.expand_path('../../../config/me.yml', __FILE__))).result)
  end

  def env_config
    @@env_config
  end


  def my_config
    @@me
  end

  alias_method :me, :my_config
end

World(CustomConfig)
