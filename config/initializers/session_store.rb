ENV['SESSION_REDIS_URL'] ||= if ENV['REDIS_URL']
  RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'session')
else
  'redis://localhost:6379/session'
end


session_store_args = {
  servers: ENV['SESSION_REDIS_URL'],
  key: '_fhlb-member_session',
  expire_in: 20.minutes,
  secure: Rails.env.production?,
  namespace: RedisHelper.namespace_from_url(ENV['SESSION_REDIS_URL'])
}
Rails.application.config.session_store :redis_store, session_store_args

# moved the session parser up in the middleware hierarchy
Rails.application.config.middleware.delete(ActionDispatch::Cookies)
Rails.application.config.middleware.delete(ActionDispatch::Session::RedisStore)
Rails.application.config.middleware.insert_before(Rails::Rack::Logger, ActionDispatch::Session::RedisStore, session_store_args)
Rails.application.config.middleware.insert_before(ActionDispatch::Session::RedisStore, ActionDispatch::Cookies)