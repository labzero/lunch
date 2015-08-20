ENV['CACHE_REDIS_URL'] ||= if ENV['REDIS_URL']
  redis_uri = URI(ENV['REDIS_URL'])
  redis_uri.path = case redis_uri.path
  when '', '/'
    '/cache'
  when /^\/\d+(\/)?$/
    redis_uri.path + ('/' if $1.nil?).to_s + 'cache'
  else
    redis_uri.path + '-cache'
  end
  redis_uri.to_s
else
  'redis://localhost:6379/cache'
end

Rails.application.config.cache_store = :redis_store, ENV['CACHE_REDIS_URL'], { expires_in: 1.day }