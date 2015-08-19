ENV['SESSION_REDIS_URL'] ||= if ENV['REDIS_URL']
  redis_uri = URI(ENV['REDIS_URL'])
  redis_uri.path = case redis_uri.path
  when '', '/'
    '/session'
  when /^\/\d+(\/)?$/
    redis_uri.path + ('/' if $1.nil?).to_s + 'session'
  else
    redis_uri.path + '-session'
  end
  redis_uri.to_s
else
  'redis://localhost:6379/session'
end

session_store_args = {servers: ENV['SESSION_REDIS_URL'], key: '_fhlb-member_session', expire_in: 20.minutes, secure: Rails.env.production? }
Rails.application.config.session_store :redis_store, session_store_args

# moved the session parser up in the middleware hierarchy
Rails.application.config.middleware.delete(ActionDispatch::Cookies)
Rails.application.config.middleware.delete(ActionDispatch::Session::RedisStore)
Rails.application.config.middleware.insert_before(Rails::Rack::Logger, ActionDispatch::Session::RedisStore, session_store_args)
Rails.application.config.middleware.insert_before(ActionDispatch::Session::RedisStore, ActionDispatch::Cookies)