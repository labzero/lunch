# Place RemoteIp before the logger to properly detect IPs on proxied requests
Rails.application.config.middleware.delete ::ActionDispatch::RemoteIp
Rails.application.config.middleware.insert_before ::Rails::Rack::Logger, ::ActionDispatch::RemoteIp, 
                                                  Rails.application.config.action_dispatch.ip_spoofing_check,
                                                  Rails.application.config.action_dispatch.trusted_proxies

# moved the session parser up in the middleware hierarchy
Rails.application.config.middleware.delete(ActionDispatch::Cookies)
Rails.application.config.middleware.delete(ActionDispatch::Session::RedisStore)
Rails.application.config.middleware.insert_before(Rails::Rack::Logger, ActionDispatch::Session::RedisStore, Rails.application.config.session_options)
Rails.application.config.middleware.insert_before(ActionDispatch::Session::RedisStore, ActionDispatch::Cookies)

# swap the default logger with our slightly customized version
Rails.application.config.middleware.swap(Rails::Rack::Logger, FhlbMember::Rack::Logger, Rails.application.config.log_tags)

# Add shared LDAP connection middleware before Warden
Rails.application.config.middleware.insert_before(Warden::Manager, FhlbMember::Rack::LDAPSharedConnection)

Rails.application.config.middleware.use Flipper::Middleware::Memoizer, -> { Rails.application.flipper }