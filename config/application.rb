require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FhlbMember
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.time_zone = ENV['TIMEZONE'] || 'Pacific Time (US & Canada)'

    config.mapi = ActiveSupport::OrderedOptions.new
    config.mapi.endpoint = ENV['MAPI_ENDPOINT'] || 'http://localhost:3100/mapi'

    config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
    config.log_tags = [
      lambda { |request| "time=#{Time.zone.now.iso8601}" },
      lambda { |request| "request_id=#{request.uuid}" },
      lambda { |request| "session_id=#{request.session.id}" },
      lambda { |request| request.session["warden.user.user.key"].nil? ? "user_id=NONE" : "user_id=#{request.session["warden.user.user.key"][0][0]}" },
      lambda { |request| "remote_ip=#{request.remote_ip}" }
    ]
    config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 'daily'))
    config.active_job.queue_adapter = :resque

    config.active_record.raise_in_transactional_callbacks = true

    # autoload files in the lib directory
    config.autoload_paths << Rails.root.join('lib')

    # hide securid details
    config.filter_parameters << [:securid_pin, :securid_token, :securid_new_pin, :securid_confirm_pin]

    config.action_view.field_error_proc = Proc.new { |html_tag, instance|
      "#{html_tag}".html_safe
    }

    trusted_proxies = (ENV['TRUSTED_PROXIES'] || '').split.collect { |proxy| IPAddr.new(proxy) }
    config.action_dispatch.trusted_proxies = trusted_proxies + ActionDispatch::RemoteIp::TRUSTED_PROXIES

    config.action_dispatch.default_headers = {
      'Pragma' => 'no-cache',
      'Cache-Control' => 'no-store'
    }

    config.x.advance_request.key_expiration = 1.hour

    # Configure our cache

    config.before_configuration do
      require Rails.root.join('lib', 'redis_helper')
      
      ENV['CACHE_REDIS_URL'] ||= if ENV['REDIS_URL']
        ::RedisHelper.add_url_namespace(ENV['REDIS_URL'], 'cache')
      else
        'redis://localhost:6379/cache'
      end

      cache_store_args = {
        namespace: ::RedisHelper.namespace_from_url(ENV['CACHE_REDIS_URL']),
        expires_in: 1.day
      }
      config.cache_store = :redis_store, ENV['CACHE_REDIS_URL'], cache_store_args
    end
  end
end
