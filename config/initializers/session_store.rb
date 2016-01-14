require_relative Rails.root.join('lib', 'redis-sessions', 'store')
require_relative Rails.root.join('lib', 'redis-sessions', 'marshalling')
require_relative Rails.root.join('lib', 'redis-sessions', 'namespace')

ENV['SESSION_REDIS_URL'] ||= if ENV['REDIS_URL']
  RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'session')
else
  'redis://localhost:6379/session'
end


session_store_args = {
  servers: [{ url: ENV['SESSION_REDIS_URL'], namespace: RedisHelper.namespace_from_url(ENV['SESSION_REDIS_URL'])}],
  key: '_fhlb-member_session',
  expire_after: 20.minutes,
  secure: Rails.env.production?
}
Rails.application.config.session_store :redis_store, session_store_args
